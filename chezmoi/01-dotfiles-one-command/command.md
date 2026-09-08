# chezmoi で dotfiles を 1 コマンド化 - コマンドと設定のまとめ

動画「chezmoi で Mac も Linux も WSL も同じ dotfiles にする」で紹介したコマンドと設定です。
実例として紹介した dotfiles は https://github.com/reisuta/dotfiles にあります。

## インストールと最初の 1 行

```sh
sh -c "$(curl -fsLS get.chezmoi.io)"                        # chezmoi をインストール（単一バイナリ）
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply <GitHubユーザー名>   # 取得 → clone → apply まで 1 行
brew install chezmoi          # macOS
sudo pacman -S chezmoi        # Arch Linux
```

## 日常のコマンド

```sh
chezmoi init                          # ソース（~/.local/share/chezmoi）を作る
chezmoi add ~/.zshrc                  # 既存ファイルをソースに取り込む（dot_zshrc になる）
chezmoi add --template ~/.gitconfig   # テンプレートとして取り込む（dot_gitconfig.tmpl）
chezmoi add --encrypt ~/.netrc        # 暗号化して取り込む（encrypted_private_dot_netrc.age）
chezmoi managed                       # 管理対象の一覧
chezmoi edit ~/.zshrc                 # ソース側をエディタで開く
chezmoi diff                          # ソースとホームの差分
chezmoi apply -v                      # 反映（-v で何をしたか表示）
chezmoi re-add                        # ホーム側で直したファイルをソースに取り込み直す
chezmoi update                        # git pull して apply
chezmoi cd                            # ソースディレクトリでサブシェルを開く
chezmoi source-path                   # ソースのパスを表示
chezmoi cat ~/.gitconfig              # テンプレート展開後・復号後の中身を表示
chezmoi execute-template '{{ .chezmoi.os }} / {{ .chezmoi.arch }}'   # 式を試す
chezmoi chattr +template ~/.gitconfig # 既存ファイルをテンプレートに変える
chezmoi doctor                        # 診断
```

## ファイル名の規則（ソース側）

| 接頭辞・接尾辞 | 効果 |
|---|---|
| `dot_` | 先頭にドットを付けて配る（`dot_zshrc` → `.zshrc`） |
| `private_` | パーミッションから group と other を落とす（0600 / 0700） |
| `executable_` | 実行権限を付ける |
| `encrypted_` | 暗号化して保存（age / GPG） |
| `symlink_` | シンボリックリンクとして配る |
| `exact_` | ディレクトリ内の管理外ファイルを削除する |
| `run_` | スクリプトとして実行する |
| `run_once_` | 一度だけ実行（中身が変わると再実行） |
| `run_onchange_` | 中身が変わったときに実行 |
| `run_once_before_` / `run_once_after_` | apply の前 / 後に実行 |
| `.tmpl` | Go テンプレートとして処理 |

接頭辞は連結できる（例: `private_executable_dot_local`）。順序は決まっているので、迷ったら `chezmoi add` に作らせる。

## テンプレートの例（OS で切り替える）

`dot_gitconfig.tmpl`

```
[user]
    name = your-name
    email = you@example.com
[credential]
{{ if eq .chezmoi.os "darwin" -}}
    helper = osxkeychain
{{ else -}}
    helper = cache
{{ end -}}
```

## .chezmoiignore.tmpl の例（OS で配るファイルを変える）

```
README.md
Brewfile
{{ if eq .chezmoi.os "darwin" -}}
.config/i3
.config/sway
.config/waybar
{{ end -}}
{{ if (.chezmoi.kernel.osrelease | lower | contains "microsoft") -}}
.config/kitty
{{ end -}}
```

## スクリプトの例（パッケージリストが変わったら再実行）

`run_once_before_install-packages.sh.tmpl`

```sh
#!/bin/bash
# リストのハッシュをコメントに埋め込む。リストが変わるとスクリプトの中身が変わり、再実行される
#   Brewfile: {{ include "Brewfile" | sha256sum }}
set -euo pipefail
{{ if eq .chezmoi.os "darwin" -}}
brew bundle --file="{{ .chezmoi.sourceDir }}/Brewfile"
{{ else if eq .chezmoi.osRelease.id "arch" -}}
sudo pacman -S --needed - < "{{ .chezmoi.sourceDir }}/archpkgs.txt"
{{ end -}}
```

## 暗号化（age）

`~/.config/chezmoi/chezmoi.toml`

```toml
encryption = "age"
[age]
    identity = "~/.config/chezmoi/key.txt"
    recipient = "age1..."
```

```sh
age-keygen -o ~/.config/chezmoi/key.txt   # 鍵を作る（公開鍵が recipient）
chezmoi add --encrypt ~/.netrc
```

## 外部ファイルの取り込み

`.chezmoiexternal.toml`

```toml
[".vim/autoload/plug.vim"]
    type = "file"
    url = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    refreshPeriod = "168h"

[".oh-my-zsh"]
    type = "archive"
    url = "https://github.com/ohmyzsh/ohmyzsh/archive/master.tar.gz"
    exact = true
    stripComponents = 1
    refreshPeriod = "168h"
```

## Nix（home-manager）との使い分け

| 観点 | chezmoi | Nix + home-manager |
|---|---|---|
| 管理するもの | 設定ファイル | パッケージと設定ファイル |
| 書き方 | 今あるファイルをそのまま | Nix 言語で宣言 |
| ロールバック | git | 世代の切り替え |
| 対応 OS | Linux / macOS / Windows | Linux / macOS（Windows は WSL 経由） |
| 向いている用途 | 設定を複数マシンに配る | 環境全体をバージョンまで固定して再現する |
