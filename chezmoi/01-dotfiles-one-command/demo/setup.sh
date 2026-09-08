#!/usr/bin/env bash
# 動画の実演を再現するための隔離した HOME を /tmp/cz/home に作る。
#   bash demo/setup.sh <scenario>   scenario: fresh | added | secret | repo
#   作ったあとは `export HOME=/tmp/cz/home` してから chezmoi を叩くと、本物のホームに触れずに試せる。
# 触るのは /tmp/cz だけ（実行のたびに削除して作り直す）。global の git 設定や本物の ~/.local/share/chezmoi は変更しない。
# 必要なもの: chezmoi、git。secret シナリオは age（age-keygen）も使う。
# .netrc のトークンとメールアドレスはすべてダミー。
set -euo pipefail
rm -rf /tmp/cz; mkdir -p /tmp/cz/home /tmp/cz/home2
H=/tmp/cz/home
cat > "$H/.zshrc" <<'Z'
export EDITOR=nvim
alias ll='ls -la'
eval "$(starship init zsh)"
Z
cat > "$H/.gitconfig" <<'G'
[user]
	name = demo
	email = demo@example.com
[core]
	editor = nvim
G
mkdir -p "$H/.config/kitty"; echo "font_size 14" > "$H/.config/kitty/kitty.conf"
printf 'machine api.example.com\nlogin demo\npassword s3cr3t-token-1234\n' > "$H/.netrc"; chmod 600 "$H/.netrc"

init_cz() {   # chezmoi init 済み・3 ファイル add 済みの状態
  HOME=$H chezmoi init >/dev/null 2>&1
  HOME=$H chezmoi add "$H/.zshrc" "$H/.gitconfig" "$H/.config/kitty/kitty.conf" >/dev/null 2>&1
}
case "${1:-fresh}" in
  fresh) ;;
  added) init_cz ;;
  secret)
    init_cz
    age-keygen -o /tmp/cz/key.txt >/tmp/cz/keygen.log 2>&1
    PUB=$(grep -o 'age1[0-9a-z]*' /tmp/cz/keygen.log | head -1)
    mkdir -p "$H/.config/chezmoi"
    printf 'encryption = "age"\n[age]\n  identity = "/tmp/cz/key.txt"\n  recipient = "%s"\n' "$PUB" > "$H/.config/chezmoi/chezmoi.toml"
    ;;
  repo)   # init --apply 用: 設定を git リポジトリにまとめて /tmp/cz/repo に置く
    init_cz
    SRC="$H/.local/share/chezmoi"
    (cd "$SRC" && HOME=$H git add -A && HOME=$H git commit -q -m "my dotfiles") 
    git clone -q --bare "$SRC" /tmp/cz/repo
    ;;
  *) echo "unknown scenario: $1" >&2; exit 1 ;;
esac
