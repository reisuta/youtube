#!/usr/bin/env bash
# 動画の実演用リポジトリを /tmp/worktree-demo に作り直す。
#   bash demo/setup.sh            作る（毎回削除して作り直す）
#   bash demo/setup.sh conflict   3 本のブランチを作り、api と docs を「合流で衝突する」状態にしておく（06_merge 用）
# 触るのは /tmp/worktree-demo とその配下だけ。実ホーム・実リポジトリ・global 設定・~/.claude には触れない。
# tmux は専用のサーバー（-L wtdemo）と設定（demo/tmux.conf）で動かし、ログインシェルの rc を読ませない。
# 必要なもの: bash、git 2.28 以上、jq、tmux、node（npm test 用）。
set -euo pipefail
D=/tmp/worktree-demo
tmux -L wtdemo kill-server 2>/dev/null || true
rm -rf "$D"
mkdir -p "$D"/{src,test,docs,scripts,.claude/hooks}
cd "$D"
git init -q -b main
git config user.name "demo"
git config user.email "demo@example.com"
git config core.pager cat
git config color.ui always
git config rerere.enabled true

# ---- 小さな Node アプリ（前回のハーネスの動画と同じ形） ----
cat > package.json <<'EOF'
{
  "name": "worktree-demo",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" }
}
EOF
cat > src/user.js <<'EOF'
// 共通の型。auth と api の両方が触るので、合流で衝突する
export function makeUser(name) {
  return { name };
}
EOF
cat > src/auth.js <<'EOF'
import { makeUser } from "./user.js";
export function login(name) {
  return makeUser(name);
}
EOF
cat > src/api.js <<'EOF'
import { makeUser } from "./user.js";
export function getUser(name) {
  return makeUser(name);
}
EOF
cat > src/log.js <<'EOF'
export function log(msg) {
  console.log(`[app] ${msg}`);
}
EOF
cat > test/app.test.js <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { login } from "../src/auth.js";
import { getUser } from "../src/api.js";
test("login", () => assert.equal(login("alice").name, "alice"));
test("getUser", () => assert.equal(getUser("bob").name, "bob"));
EOF
cat > docs/README.md <<'EOF'
# worktree-demo
小さなサンプル。auth / api / docs を 3 つの worktree で並列に進める。
EOF
printf 'node_modules/\n.env\n.claude/worktrees/\n' > .gitignore
printf '.env\n' > .worktreeinclude
printf 'API_KEY=dummy-for-demo\n' > .env           # gitignore 済み。.worktreeinclude で worktree にコピーされる例

# ---- CLAUDE.md と hook（前回 claude/3 の bash-guard を再利用） ----
cat > CLAUDE.md <<'EOF'
# worktree-demo
- 作業は worktree ごとに 1 issue。main に直接 commit しない（hook が止める）。
- src/ を編集したら `npm test` を通す。
EOF
cat > .claude/settings.json <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/bash-guard.sh" }] }
    ]
  }
}
EOF
cat > .claude/hooks/bash-guard.sh <<'EOF'
#!/usr/bin/env bash
# PreToolUse (Bash): main ブランチでの commit / push と、本体に向けた git を止める。
# CLAUDE_PROJECT_DIR は本体のまま。今いる worktree は JSON の cwd で受け取る。
set -euo pipefail
input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
cwd=$(jq -r '.cwd // ""' <<<"$input")
branch=$(git -C "${cwd:-.}" branch --show-current 2>/dev/null || echo "")
if [[ "$cmd" =~ git[[:space:]]+(commit|push) ]] && [[ "$branch" == "main" ]]; then
  echo "拒否: main での git commit / push は禁止です。worktree のブランチで作業してください（CLAUDE.md）。" >&2
  exit 2
fi
if [[ "$cmd" =~ git[[:space:]]+-C[[:space:]]+/tmp/worktree-demo([[:space:]]|$) ]]; then
  echo "拒否: 本体の作業ツリーに向けた git は worktree の中から実行しません。" >&2
  exit 2
fi
echo "ok: cwd=$cwd branch=$branch" >&2
exit 0
EOF
# 前回（claude/3）の hook そのまま。CLAUDE_PROJECT_DIR でブランチを見るので、worktree の中では本体の main を見てしまう（罠の実演用）
cat > .claude/hooks/bash-guard-old.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
branch=$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null || echo "")
if [[ "$cmd" =~ git[[:space:]]+(commit|push) ]] && [[ "$branch" == "main" ]]; then
  echo "拒否: main ブランチ上での git commit / push は禁止です。" >&2
  exit 2
fi
exit 0
EOF
chmod +x .claude/hooks/bash-guard.sh .claude/hooks/bash-guard-old.sh

# ---- tmux の設定（ログインシェルを使わない。見出しにブランチ名） ----
cat > scripts/tmux.conf <<'EOF'
set -g default-command "bash --noprofile --rcfile /tmp/worktree-demo/scripts/bashrc"
set -g status-style "bg=#1f6f3a,fg=#e8f5e9"
set -g status-left "[#S] "
set -g status-right ""
set -g pane-border-status top
set -g pane-border-format " #{pane_title} "
set -g pane-border-style "fg=#3a5a40"
set -g pane-active-border-style "fg=#5ac46a"
set -g mouse off
EOF
cat > scripts/bashrc <<'EOF'
PS1='\W ❯ '
export PAGER=cat GIT_PAGER=cat
EOF

# ---- 偽のエージェント: worktree の中で commit を重ねるだけ（本番では claude --name <名前> に置き換える） ----
cat > scripts/agent.sh <<'EOF'
#!/usr/bin/env bash
# usage: agent.sh <name> [回数]   その worktree の src/<name>.js に行を足しては commit する
set -euo pipefail
name=$1; n=${2:-4}
printf '\033]2;%s\033\\' "$(git branch --show-current)"     # ペインのタイトルにブランチ名
for i in $(seq 1 "$n"); do
  sleep $((RANDOM % 2 + 1))
  echo "// $name: step $i" >> "src/$name.js"
  git add -A && git commit -q -m "$name: step $i"
  echo "[$name] commit $i: $(git log --oneline -1)"
done
echo "[$name] done"
EOF
chmod +x scripts/agent.sh

# ---- 3 ペインを組むスクリプト（本編の主役） ----
cat > scripts/parallel.sh <<'EOF'
#!/usr/bin/env bash
# usage: parallel.sh auth api docs   各名前の worktree を .claude/worktrees/<name> に作り、tmux のペインで 1 つずつ起動する
set -euo pipefail
S=wtdemo
root=$(git rev-parse --show-toplevel)
for name in "$@"; do
  wt="$root/.claude/worktrees/$name"
  [ -d "$wt" ] || git worktree add -q "$wt" -b "worktree-$name"
  [ -f "$root/.env" ] && cp -n "$root/.env" "$wt/.env"            # .worktreeinclude 相当（Claude Code は自動でやる）
done
tmux -L $S -f "$root/scripts/tmux.conf" new-session -d -s $S -x 160 -y 40 -c "$root/.claude/worktrees/$1"
i=0
for name in "$@"; do
  wt="$root/.claude/worktrees/$name"
  [ $i -gt 0 ] && tmux -L $S split-window -h -t $S -c "$wt"
  # 本番: tmux -L $S send-keys -t $S:0.$i "claude --name $name" Enter
  tmux -L $S send-keys -t $S:0.$i "bash $root/scripts/agent.sh $name" Enter
  i=$((i+1))
done
tmux -L $S select-layout -t $S even-horizontal
echo "tmux -L $S attach -t $S   # prefix + d で抜ける"
EOF
chmod +x scripts/parallel.sh

git add -A >/dev/null && git commit -q -m "initial"

# ---- conflict: 3 本のブランチを作り、api と docs を「合流で衝突する」状態に ----
if [ "${1:-}" = conflict ]; then
  for name in auth api docs; do
    git worktree add -q ".claude/worktrees/$name" -b "worktree-$name"
  done
  # auth: 共通の型に role を足す（先に merge する）
  ( cd .claude/worktrees/auth
    cat > src/user.js <<'EOF'
// 共通の型。auth と api の両方が触るので、合流で衝突する
export function makeUser(name, role = "member") {
  return { name, role };
}
EOF
    echo 'export function logout() { return null; }' >> src/auth.js
    git add -A && git commit -q -m "auth: add role to user and logout()" )
  # api: 同じ行を別の形で変える（rebase で衝突する）
  ( cd .claude/worktrees/api
    cat > src/user.js <<'EOF'
// 共通の型。auth と api の両方が触るので、合流で衝突する
export function makeUser(name, id = 0) {
  return { name, id };
}
EOF
    echo 'export function listUsers() { return []; }' >> src/api.js
    git add -A && git commit -q -m "api: add id to user and listUsers()" )
  # docs: 触るファイルが重ならない
  ( cd .claude/worktrees/docs
    echo '- auth と api の使い方は各ファイルの先頭コメントを見る' >> docs/README.md
    git add -A && git commit -q -m "docs: usage note" )
fi
