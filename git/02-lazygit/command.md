# lazygit 完全ガイド - キーと設定のまとめ

動画「【AI が書いた差分、3 秒で読めますか】lazygit 完全ガイド」で使ったキーと設定です。
`demo/setup.sh <scenario>` で `/tmp/lazygit-demo` に実演用の Ruby の小さなリポジトリができます。触るのは `/tmp/lazygit-demo` だけです。

必要なもの: git 2.28 以上、lazygit 0.55 以上（`-` で 1 つ前のブランチが 0.55、`N` が 0.50、customCommands の `output:` が 0.44 で追加。`brew install lazygit` / `sudo pacman -S lazygit` / `go install github.com/jesseduffield/lazygit@latest`）、ruby（テスト用）。動画は lazygit 0.65 で撮影。

## サンプルを作る

```sh
bash demo/setup.sh base      # 6 コミットの Ruby アプリ
bash demo/setup.sh read      # AI が出した 1 つの大きな差分（3 ファイル、関心事が 3 つ混ざる）
bash demo/setup.sh fix       # 3 コミット積んだ後に 1 つ目への修正が残っている
bash demo/setup.sh rebase    # 雑な 5 コミット（WIP・typo・順番違い）
bash demo/setup.sh undo      # reset --hard で 2 コミット消した直後
bash demo/setup.sh branch    # feature 2 本と stash 1 つ
LG_CONFIG_FILE="$PWD/demo/config.yml"; cd /tmp/lazygit-demo && lazygit --use-config-file "$LG_CONFIG_FILE"   # このディレクトリで実行
```

## 設定（`demo/config.yml`）

置き場所は macOS が `~/Library/Application Support/lazygit/config.yml`、Linux が `~/.config/lazygit/config.yml`。`--use-config-file` か環境変数 `LG_CONFIG_FILE` で別の場所を指せる。

```yaml
disableStartupPopups: true     # 起動時のポップアップを出さない
update:
  method: never                # 更新確認をしない（既定は 14 日ごとに prompt）
gui:
  nerdFontsVersion: "3"        # Nerd Font v3 のアイコン。無ければ ""（既定）
  language: en                 # ja もある
  showCommandLog: true         # 右下に実行した git コマンドを出す
os:
  editPreset: nvim             # e で開くエディタ。vim / nvim / vscode / helix など
customCommands:
  - key: "!"
    context: "global"          # どのパネルでも効く。files / commits / localBranches などに絞れる
    command: "ruby test/app_test.rb"
    description: "run tests"
    output: terminal           # ターミナルに出して Enter を待つ
```

customCommands のテンプレートで、選んでいるものを受け取れる。例: Files パネルで選んだテストファイルだけ回す（コミットなら `{{.SelectedCommit.Hash}}`、ブランチなら `{{.SelectedLocalBranch.Name}}`）。

```yaml
  - key: "t"
    context: "files"
    command: "ruby {{.SelectedFile.Name}}"
    description: "run this test file"
    output: terminal
```

## キー（既定）

### 共通

| キー | 動き |
|---|---|
| `1` `2` `3` `4` `5` | パネルへ飛ぶ（Status / Files / Branches / Commits / Stash） |
| `j` `k` / `h` `l` | 上下 / 前後のパネルへ（`Tab` も同じ） |
| `[` `]` | パネル内のタブ切替 |
| `Tab` | 次のパネル |
| `Enter` | 中に入る（ファイルなら行の画面、コミットならそのコミットのファイル） |
| `Esc` | 1 つ戻る |
| `?` | そのパネルのキー一覧 |
| `@` | Command log のメニュー（表示・非表示、フォーカス） |
| `z` / `Z` | undo / redo（reflog から逆の操作を提案。作業ツリーの未コミット分は対象外） |
| `P` / `p` | push / pull |
| `W` | 2 つの ref の間の差分（diffing） |
| `Ctrl+s` | コミット一覧をファイル名や作者で絞る |
| `/` | パネル内を検索 |
| `Ctrl+w` | 空白の変更を無視 |
| `{` `}` | diff の前後に見せる行数を減らす / 増やす |
| `J` `K` | 右のメイン表示をスクロール |
| `m` | merge / rebase の continue・abort・skip |
| `:` | シェルコマンドを実行 |
| `q` | 終了 |

### Files（`2`）

| キー | 動き |
|---|---|
| `Space` | ステージ / 戻す |
| `a` | 全部ステージ / 全部戻す |
| `Enter` | 行の画面へ |
| `c` | commit（`w` は pre-commit hook を飛ばす、`C` は git のエディタで） |
| `A` | 直前のコミットに amend |
| `d` | 変更を捨てる（確認あり。戻らない） |
| `s` / `S` | stash / stash の種類を選ぶ（ステージ分だけ、など） |
| `e` / `o` | エディタで開く / 既定アプリで開く |
| `i` | .gitignore に追加 |
| `Ctrl+f` | この変更を混ぜるべきコミットを探す |
| `` ` `` | ツリー表示と一覧表示の切替 |
| `]` | 隣のタブ（Worktrees / Submodules） |

### 行の画面（Files で `Enter`）

| キー | 動き |
|---|---|
| `Space` | 選んだ行 / 範囲をステージ（ステージ側なら戻す） |
| `v` | 範囲選択の開始 / 終了 |
| `a` | 行単位と hunk 単位の切替 |
| `h` `l` | 前の hunk / 次の hunk |
| `d` | 選んだ行の変更を捨てる |
| `Tab` | ステージ済み / 未ステージの画面を切替 |
| `c` | ステージした分で commit |
| `Esc` | Files に戻る |

### Commits（`4`）

| キー | 動き |
|---|---|
| `Enter` | そのコミットのファイル一覧 |
| `Space` | そのコミットを checkout（detached） |
| `s` / `f` | 下のコミットに squash（メッセージを残す / 捨てる） |
| `d` | drop |
| `r` / `R` | reword（入力 / エディタ） |
| `e` / `i` | そのコミットから interactive rebase を手動で始める / ブランチ全体で始める |
| `Ctrl+k` `Ctrl+j` | 上 / 下に並べ替え |
| `F` | このコミットへの `fixup!` コミットを作る |
| `S` | 上に積まれた `fixup!` を全部畳む（autosquash） |
| `A` | ステージ分をこのコミットに amend（HEAD 以外は rebase で差し込む） |
| `g` | このコミットまで reset（soft / mixed / hard を選ぶ） |
| `C` / `V` | cherry-pick のコピー / 貼り付け |
| `t` | revert |
| `T` | tag |
| `n` | このコミットからブランチを作る |
| `]` | 隣のタブ（Reflog） |

### Branches（`3`）

| キー | 動き |
|---|---|
| `Space` | checkout |
| `n` | 新しいブランチ |
| `N` | 未 push のコミットを新しいブランチへ移す（main で作業を始めてしまったとき） |
| `c` / `-` | 名前で checkout / 1 つ前のブランチへ |
| `r` | 今のブランチを選んだブランチの上に rebase |
| `M` | 選んだブランチを今のブランチに merge |
| `f` | 選んだブランチを upstream まで fast-forward（pull せずに main を最新にする） |
| `d` | 削除 |
| `R` | 名前変更 |
| `w` | 新しい worktree（一覧と切り替えは Files パネルの Worktrees タブ） |
| `]` | 隣のタブ（Remotes / Tags） |

### Stash（`5`）

| キー | 動き |
|---|---|
| `Space` | apply |
| `g` | pop |
| `d` | drop |
| `n` | stash からブランチを作る |

## 気をつけること

- `d`（捨てる）と `g` の hard は戻らない。確認画面を読む。
- Commits パネルの s / f / d / r / 並べ替えは、裏で interactive rebase が走る。push 済みのコミットにはしない。
- `z` は commit の状態だけ戻す。作業ツリーの未コミットの変更は `d` で捨てたら戻らない。
- Neovim から開くなら `lazygit.nvim` か `toggleterm.nvim` のフロート。
