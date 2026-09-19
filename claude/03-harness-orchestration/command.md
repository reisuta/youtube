# CLAUDE.md が守られない理由と、Claude Code を自律で回す設計 - サンプルと設定のまとめ

動画「【auto mode で放置できますか】CLAUDE.md が守られない理由と、Claude Code を自律で回す設計」で使ったサンプルプロジェクトの生成スクリプトと、各部品の書き方です。
`demo/setup.sh` を実行すると `/tmp/harness-demo` に hooks・skills・rules・agents・workflows 一式が入った Node プロジェクトができます。実ホームや `~/.claude` には触れません。

**注意**: サンプルの hook は Claude Code v2.1 系の仕様（PreToolUse / PostToolUse / Stop、exit 2 で block、`hookSpecificOutput`）に合わせています。公式ドキュメント https://code.claude.com/docs/en/hooks を正としてください。

## サンプルを作る

```sh
bash demo/setup.sh            # /tmp/harness-demo を削除して作り直す（触るのはこのディレクトリと $TMPDIR/claude-hooks-demo-<uid>/ だけ）
cd /tmp/harness-demo && tree -a -I '.git|node_modules' .claude
```

必要なもの: bash、jq、git、Node.js（`npm test` 用）。macOS と Debian で動作確認済み。`file-guard.sh` にある `ghp_` や `AKIA` は検出用の正規表現で、実在のトークンではありません。

## 判断基準（どの部品にするか）

| 状況 | 部品 | 置き場所 |
|---|---|---|
| 毎回必要な事実（コマンド、規約の要点） | CLAUDE.md（200 行以内） | `./CLAUDE.md` |
| 特定パスにだけ効く規約 | rule | `.claude/rules/*.md` + `paths:` |
| 機械的に白黒がつく禁止事項 | hook（PreToolUse） | `.claude/hooks/*.sh` + `.claude/settings.json` |
| 「応答を結ぶ前に X したか」の催促 | hook（Stop、1 回だけ） | 同上 |
| 判断を伴う定型手順 | skill | `.claude/skills/<name>/SKILL.md` |
| 出力が長い・道具を絞りたい・並列 | subagent | `.claude/agents/*.md` |
| 手順をコードにして数十エージェントを回す | workflow | `.claude/workflows/*.js` |
| 会話が消えても残す状態 | plan ファイル | `dev/tasks/*.md` |

## hook の単体テスト（Claude Code を起動せずに試す）

```sh
cd /tmp/harness-demo
# 拒否される例: main で push → exit 2、stderr に理由・代替手順・出典
echo '{"session_id":"demo","tool_name":"Bash","tool_input":{"command":"git push origin main"}}' \
  | CLAUDE_PROJECT_DIR=$PWD .claude/hooks/bash-guard.sh; echo "exit=$?"
# 通る例
echo '{"tool_name":"Bash","tool_input":{"command":"git status"}}' | .claude/hooks/bash-guard.sh; echo "exit=$?"
# 秘密らしき文字列の書き込み → 拒否
echo '{"tool_name":"Write","tool_input":{"file_path":"src/config.js","content":"const t = \"ghp_xxxxxxxxxxxxxxxxxxxxxxxx\""}}' \
  | .claude/hooks/file-guard.sh; echo "exit=$?"
# Stop の一往復: 編集 → marker → Stop は block（1 回だけ）→ npm test 成功で marker が消える
echo '{"session_id":"demo","tool_name":"Edit","tool_input":{"file_path":"src/app.js","new_string":"x"}}' | .claude/hooks/track-edit.sh
echo '{"session_id":"demo"}' | .claude/hooks/stop-test-reminder.sh          # {"decision":"block","reason":"..."}
echo '{"session_id":"demo"}' | .claude/hooks/stop-test-reminder.sh          # 2 回目は何も出ない（exit 0）
echo '{"session_id":"demo","tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"stdout":"# fail 0"}}' \
  | .claude/hooks/track-test-run.sh
```

hook の契約:

| 終了コード | 意味 | モデルに返るもの |
|---|---|---|
| 0 | 通す | stdout（SessionStart / UserPromptSubmit では文脈に追加。JSON なら `hookSpecificOutput` を解釈） |
| 2 | 止める | stderr の文章、または JSON の reason |
| その他 | エラーだが通す | 通知のみ |

`.claude/settings.json` の登録例:

```json
{
  "permissions": { "allow": ["Bash(npm test)"], "deny": ["Bash(git push --force *)", "Read(./.env)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash",       "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/bash-guard.sh" }] },
      { "matcher": "Edit|Write", "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/file-guard.sh" }] }
    ],
    "Stop": [{ "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/stop-test-reminder.sh" }] }]
  }
}
```

Stop hook の要点: `stop_hook_active` が true なら即 exit 0（無限ループ防止。Claude Code 側も進展の無い block が 8 回続くと催促を無視するが、それに頼らない）。marker は `$TMPDIR/claude-hooks-demo-<uid>/<session_id>.src-dirty`。催促は `reminded` ファイルより marker が新しいときだけ。

判断を伴う検査（「命名が読みやすいか」など）はシェルの hook では書けない。`"type": "prompt"` の hook なら軽いモデル（既定 Haiku）に判定させられるが、イベントごとに費用と待ちが増えるので、普段は skill の確認項目にする。`"type": "agent"` は実験的。

## skill の雛形

```markdown
---
name: quality-gate
description: 区切りごとの品質ゲート。「区切り」「PR 前」と言われたら使う。   # いつ使うか
allowed-tools: Bash(npm test) Bash(npm run build) Bash(git diff *)          # そのターンだけ許可（制限ではない）
# disable-model-invocation: true   # 人間しか呼べなくする（作業開始やデプロイ）
# context: fork                    # 別文脈で走らせて要約だけ受け取る
---
# 品質ゲート
真実源: docs/design.md「作業の原則」（本文を複製しない）
## 手順
1. `npm test` …
3. 設計書に無い変更があれば **ユーザーに確認する**
## やらないこと
- …
```

## rule の雛形

```markdown
---
paths:
  - "src/api/**/*.js"
---
# API 層の規約（真実源: docs/design.md）
- …
```

## subagent の雛形

```markdown
---
name: reviewer
description: 差分を読んで正確性と設計書との整合だけをレビューする。書き換えはしない。
tools: Read, Grep, Glob        # ツール名だけ。Bash(git diff *) のようなコマンド単位の指定は効かない（Bash ごと渡すか渡さないか）
model: sonnet
maxTurns: 15
---
あなたはレビュアーです。…（本文がシステムプロンプト）
```

Bash を渡したうえで特定のコマンドだけ止めたいなら、`tools` ではなく `permissions.deny` の `Bash(git push *)` か PreToolUse hook で行う。

## workflow の雛形（`.claude/workflows/review-changes.js`）

```javascript
export const meta = { name: 'review-changes', description: '変更ファイルをレビューし、指摘を別のエージェントに検証させる' }
const changed = await agent('git diff --name-only main を実行し、変更ファイルの一覧を返す。',
  { schema: { type: 'object', required: ['files'], properties: { files: { type: 'array', items: { type: 'string' } } } } })
const results = await pipeline(
  changed.files,
  f => agent(`${f} を docs/design.md の原則と照らしてレビューし、指摘を列挙する。`, { label: `review:${f}` }),
  review => agent(`次の指摘が本当に問題か、反証を探して検証する: ${review}`, { label: 'verify' }),
)
return results.filter(Boolean)
```

`ultracode: …` か「use a workflow」でモデルに書かせ、`/workflows` で保存すると `/review-changes` として再利用できる。エージェント数と費用は `/config workflowSizeGuideline=small` で抑える。

## 無人で回す（`scripts/nightly.sh`）

```sh
claude --bare -p "依存関係を更新して npm test を通す。通らなければ何も変更せず理由を報告する" \
  --settings .claude/settings.json \
  --permission-mode auto --permission-prompts none \
  --allowedTools "Bash(npm *),Read,Edit" \
  --output-format json | jq -r '.result, "cost: \(.total_cost_usd) USD"'
```

- `--bare`: ホストの hooks / skills / MCP / auto memory / CLAUDE.md を読まない（CI で同じ結果に）。サブスクのログインは使わず `ANTHROPIC_API_KEY` が必要
- `--settings .claude/settings.json`: bare は**プロジェクトの** hooks と permissions も読まないので明示して渡す。これが無いと第 3 章の guard が効かない
- `--permission-mode auto`: `-p` の既定はどのプランでも手動なので指定する。分類器が審査。`--permission-prompts none`（v2.1.259+）: 人が答えるべき要求は拒否扱い
- `--allowedTools`: 権限ルールの構文。`Bash(npm *)` の空白付き `*` が前方一致
- `--output-format json`: `result` と `total_cost_usd` を機械で読む

## auto mode にする前のチェックリスト

1. 外に出る操作（push、デプロイ）を hook で hard block しているか
2. 生成物・禁止パスへの書き込みを hook で止めているか
3. 拒否メッセージに理由・代替手順・出典があるか
4. Stop の催促は 1 回だけで、`stop_hook_active` を見ているか
5. 定型手順は skill になっていて、人間の確認点が明示されているか
6. 勝手に始めてほしくない skill は `disable-model-invocation: true` か
7. CLAUDE.md は 200 行以内で、パス固有の規約は rule に出ているか
8. subagent の tools / model / maxTurns は絞られているか
9. 会話が消えても plan ファイルだけで再開できるか
10. 「やらないこと」「設計書に無いものを作らない」が真実源にあるか
