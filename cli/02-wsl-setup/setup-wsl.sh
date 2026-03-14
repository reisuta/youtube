#!/bin/bash
# WSL (Ubuntu) 向け CLIツール 一括セットアップスクリプト

set -e

echo "=== WSL CLIツール セットアップ開始 ==="

# -------------------------
# 1. Homebrew のインストール
# -------------------------
if ! command -v brew &>/dev/null; then
  echo "[1/6] Homebrew をインストール中..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Homebrew を PATH に追加（ARM/x86両対応）
  if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.zshrc
  fi
else
  echo "[1/6] Homebrew はインストール済み、スキップ"
fi

# -------------------------
# 2. 依存パッケージ（apt）
# -------------------------
echo "[2/6] apt パッケージを更新中..."
sudo apt-get update -q
sudo apt-get install -y -q build-essential curl git zsh

# -------------------------
# 3. CLI ツール一括インストール（brew bundle）
# -------------------------
echo "[3/6] CLIツールをインストール中..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

brew bundle --file="$SCRIPT_DIR/Brewfile"

# -------------------------
# 4. .zshrc の設定追記
# -------------------------
echo "[4/6] .zshrc を設定中..."

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

append_if_missing() {
  local marker="$1"
  local block="$2"
  if ! grep -qF "$marker" "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "$block" >> "$ZSHRC"
  fi
}

append_if_missing "zoxide init zsh" \
'# zoxide
eval "$(zoxide init zsh)"'

append_if_missing "atuin init zsh" \
'# atuin
eval "$(atuin init zsh)"'

append_if_missing "mise activate zsh" \
'# mise
eval "$(mise activate zsh)"'

append_if_missing "alias ls='eza" \
'# eza
alias ls="eza --icons"
alias ll="eza -la --icons --git"'

append_if_missing "alias cat='bat'" \
'# bat
alias cat="bat"'

append_if_missing "export EDITOR=nvim" \
'# yazi - デフォルトエディタを Neovim に設定
export EDITOR=nvim'

# -------------------------
# 5. .gitconfig の設定（delta）
# -------------------------
echo "[5/6] .gitconfig を設定中..."

git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true
git config --global delta.dark true
git config --global delta.syntax-theme Dracula
git config --global delta.file-style "bold yellow"
git config --global delta.file-decoration-style "bold yellow ul"
git config --global delta.line-numbers-left-style "bold white"
git config --global delta.line-numbers-right-style "bold white"
git config --global delta.line-numbers-zero-style cyan
git config --global delta.line-numbers-minus-style red
git config --global delta.line-numbers-plus-style green

# -------------------------
# 6. yazi テーマの設定
# -------------------------
echo "[6/6] yazi テーマを設定中..."

YAZI_CONFIG_DIR="$HOME/.config/yazi"
mkdir -p "$YAZI_CONFIG_DIR"

# Catppuccin Mocha フレーバーをインストール
if command -v ya &>/dev/null; then
  ya pkg add yazi-rs/flavors:catppuccin-mocha || true
fi

# theme.toml を作成
cat > "$YAZI_CONFIG_DIR/theme.toml" << 'EOF'
# テーマ（catppuccin-mocha）
[flavor]
use = "catppuccin-mocha"

# ディレクトリの文字色を上書き
[filetype]
rules = [
  { url = "*/", fg = "cyan", bold = true },
]
EOF

# -------------------------
# 完了
# -------------------------
echo ""
echo "=== セットアップ完了！ ==="
echo ""
echo "次のコマンドで設定を反映してください:"
echo "  source ~/.zshrc"
echo ""
echo "または、ターミナルを再起動してください。"
