# git worktree × tmux で Claude Code を並列に回す - コマンドと設定のまとめ

動画「【AI に 3 つ同時に作らせる】git worktree × tmux で Claude Code を並列に回す」で使ったコマンドとスクリプトです。
`demo/setup.sh` を実行すると `/tmp/worktree-demo` に小さな Node プロジェクトと、3 ペインを組むスクリプト、偽のエージェントができます。触るのは `/tmp/worktree-demo` だけです。

必要なもの: bash、git 2.28 以上、jq、tmux、Node.js。macOS と Debian で動作確認済み。

## サンプルを作る

```sh
bash demo/setup.sh              # /tmp/worktree-demo を削除して作り直す
bash demo/setup.sh conflict     # 3 本のブランチを作り、合流で衝突する状態にする（第 6 章）
```

## git worktree

```sh
git worktree add ../repo-auth -b feature/auth   # 新しいブランチと作業ツリーを同時に作る
git worktree add ../repo-fix fix/log            # 既存ブランチをチェックアウト
git worktree list                               # 一覧（パス、コミット、ブランチ）
cat ../repo-auth/.git                           # 「gitdir: <本体>/.git/worktrees/repo-auth」の 1 行
git worktree remove ../repo-auth                # 片付け（未コミットがあれば拒否。--force で強制）
git branch -d feature/auth                      # ブランチは worktree を消した後に
git worktree prune                              # ディレクトリだけ消えた記録を掃除
git worktree lock ../repo-auth                  # prune から守る。remove も --force を 2 回付けないと消えない（unlock で戻す）
```

- 同じブランチを 2 つの worktree にチェックアウトすることはできない（`is already checked out` で拒否）。
- 新しい checkout なので、gitignore 済みのファイル（`node_modules/`、`.env`）は無い。

## claude --worktree / --tmux

```sh
claude --worktree auth        # .claude/worktrees/auth に worktree-auth ブランチで作って起動（-w でも可）
claude --worktree             # 名前は自動
claude --worktree "#1234"     # PR #1234 のブランチから作る（#, GitHub / GitLab の URL も可）
claude --worktree auth --tmux            # worktree ごとに tmux セッション。iTerm2 は native ペイン
claude --worktree auth --tmux=classic    # 従来の tmux
claude -p --worktree auth "…"            # 非対話。終了時の掃除の確認が出ないので、後で git worktree remove
```

| 項目 | 既定 | 変え方 |
|---|---|---|
| 置き場所 | `.claude/worktrees/<name>/` | `WorktreeCreate` hook で置き換え |
| ブランチ名 | `worktree-<name>` | 手で `git worktree add` |
| 分岐元 | リモートの既定ブランチ（main） | settings の `worktree.baseRef: "head"` で今の HEAD から |
| 終了時 | 変更が無ければ自動で削除。あれば残すか聞く | `-p` は聞かないので手で削除 |
| gitignore 済みファイル | コピーされない | `.worktreeinclude` に列挙（`.gitignore` 構文） |

```sh
printf '.claude/worktrees/\n' >> .gitignore     # 本体の git status に出さない
printf '.env\n.env.local\n' > .worktreeinclude  # 新しい worktree に自動コピー
```

worktree の中の Claude Code は、本体の作業ツリーへの Edit / Write、本体を作業ディレクトリにするコマンド、`git -C` や `GIT_DIR` で本体に向けた git、何を触るか読み取れない形のコマンドを拒否する。
hook の `$CLAUDE_PROJECT_DIR` は本体のまま。worktree のパスは hook の入力 JSON の `cwd` で受け取る。

**罠**: 前回（claude/3）の bash-guard は `git -C "$CLAUDE_PROJECT_DIR" branch --show-current` でブランチを見ていたので、worktree の中でも本体の `main` を見てしまい、正しいブランチでの commit まで止める。cwd で見るように直す。

```sh
# before（本体のブランチを見てしまう）
branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current)
# after（今いる worktree のブランチを見る）
cwd=$(jq -r '.cwd // ""' <<<"$input")
branch=$(git -C "${cwd:-.}" branch --show-current)
```

## tmux

```sh
tmux new-session -d -s dev -c /path/to/worktree      # 画面に出さずにセッションを作る（-c は作業ディレクトリ）
tmux split-window -h -t dev -c /path/to/another      # 右に分割（-v で下に）
tmux send-keys -t dev:0.1 "claude --name api" Enter  # セッション:ウィンドウ.ペイン に打ち込む
tmux select-layout -t dev even-horizontal            # 幅を均等に
tmux attach -t dev                                   # 入る。prefix（既定 Ctrl+b）+ d で抜ける
tmux kill-session -t dev
```

ペインの見出しにブランチ名を出す設定（`tmux.conf`）:

```
set -g pane-border-status top
set -g pane-border-format " #{pane_title} "
set -g default-command "bash --noprofile --rcfile /path/to/bashrc"   # ログインシェルの rc を読ませない
```

ペインのタイトルはシェルから `printf '\033]2;%s\033\\' "$(git branch --show-current)"` で設定できる。

## 3 ペインを組む（`scripts/parallel.sh`）

```sh
#!/usr/bin/env bash
# usage: parallel.sh auth api docs
set -euo pipefail
S=dev
root=$(git rev-parse --show-toplevel)
for name in "$@"; do
  wt="$root/.claude/worktrees/$name"
  [ -d "$wt" ] || git worktree add -q "$wt" -b "worktree-$name"
  [ -f "$root/.env" ] && cp -n "$root/.env" "$wt/.env"     # .worktreeinclude 相当
done
tmux -f "$root/scripts/tmux.conf" new-session -d -s $S -x 160 -y 40 -c "$root/.claude/worktrees/$1"
i=0
for name in "$@"; do
  wt="$root/.claude/worktrees/$name"
  [ $i -gt 0 ] && tmux split-window -h -t $S -c "$wt"
  tmux send-keys -t $S:0.$i "claude --name $name" Enter
  i=$((i+1))
done
tmux select-layout -t $S even-horizontal
echo "tmux attach -t $S"
```

動画の実演では `claude --name $name` の代わりに、commit を繰り返すだけの `scripts/agent.sh` を動かしている（本物を 3 つ回すと画面が読めないため）。

## セッション同士の連絡

- `/list-agents`（`/peers`）で、同じマシンで動いている自分の他のセッションが見える。
- プロンプトで「api のセッションに、共通の型を変えたと知らせて」と言えば、Claude が `ListAgents` と `SendMessage` で送る。`@名前` で宛先を指定できる。
- 宛先の名前は `--name` か `/rename`。受け取った側は「別のセッションからの文章」として扱い、許可の承認や設定変更の依頼は通らない。
- 受信の制御は settings の `crossSessionInbound`（`accept` / `hold` / `refuse`）。

## 合流と掃除

```sh
# main の作業ツリーで。影響の大きいブランチから 1 本ずつ
git merge --no-edit worktree-auth
(cd .claude/worktrees/api && git rebase main)      # 衝突したら直して git rebase --continue
(cd .claude/worktrees/api && npm test)
git merge --no-edit worktree-api
(cd .claude/worktrees/docs && git rebase main && npm test)
git merge --no-edit worktree-docs
git log --oneline --graph | head

# 掃除（この順で）
for n in auth api docs; do git worktree remove .claude/worktrees/$n && git branch -d worktree-$n; done
git worktree prune
git worktree list
```

`git config rerere.enabled true` にしておくと、同じ衝突は二度目から自動で解決される（前回の Git 中級テクニックの 10 番）。

## 並列にする前のチェックリスト

1. 1 worktree に 1 issue で、触るファイルが重なっていないか
2. 共有の設定と依存は、並列を始める前に main に入っているか
3. `.claude/worktrees/` は `.gitignore` に、`.env` は `.worktreeinclude` に入っているか
4. main への commit は hook で止まっているか
5. ペインごとに worktree 名が見え、セッションに `--name` が付いているか
6. 合流は 1 本ずつで、そのたびに残りを rebase してテストしているか
7. `worktree remove` → `branch -d` → `prune` の順で掃除したか
