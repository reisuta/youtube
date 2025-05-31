# 【Neovim AI開発環境】チートシート

## GitHub Copilot

### インストール
```bash
git clone --depth=1 https://github.com/github/copilot.vim.git \
  ~/.config/nvim/pack/github/start/copilot.vim
```

### 認証設定
```vim
:Copilot setup
```

`Tab`で提案を受け入れ

## Lazy.nvim

### ディレクトリ作成
```bash
mkdir -p ~/.config/nvim/lua
mkdir -p ~/.config/nvim/lua/plugins
```

### init.lua設定
```bash
nvim ~/.config/nvim/init.lua
```

```lua
-- Lazy.nvimのセットアップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

-- プラグイン設定を読み込み
require("lazy").setup("plugins")
-- キーマップを読み込み
require('keymaps')
```

### Lazy.nvimコマンド
```vim
:Lazy
```

## Ollama

### インストール

**macOS:**
- ollama.comからインストーラーをダウンロード

**Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Windows:**
- ollama.comからインストーラーをダウンロード

### モデルダウンロード

**高性能:**
```bash
ollama pull gemma3:27b
```

**中性能:**
```bash
ollama pull gemma3:12b
```

**低性能:**
```bash
ollama pull gemma3
```

### サーバー起動・動作確認
```bash
# サーバー起動
ollama serve

# 動作確認（別ターミナル）
ollama run gemma3:27b
```

## gen.nvim

### プラグイン設定
```bash
nvim ~/.config/nvim/lua/plugins/gen.lua
```

```lua
return {
  'David-Kunz/gen.nvim',
  opts = {
    model = 'gemma3:27b', -- または gemma3:12b, gemma3
    host = 'localhost',
    port = '11434',
    quit_map = 'q',
    display_mode = "vertical-split",
    show_prompt = true,
    show_model = true,
    retry_map = '<C-r>',
    init = function(options)
      pcall(io.popen, 'ollama serve > /dev/null 2>&1 &')
    end,
  },
}
```

### キーマップ設定
```bash
nvim ~/.config/nvim/lua/keymaps.lua
```

```lua
-- gen.nvim キーマップ設定
vim.keymap.set({'n', 'v'}, '<C-a>', ':Gen<CR>')
vim.keymap.set('v', 'sum', ':Gen Summarize<CR>')
vim.keymap.set('v', 'rev', ':Gen Review_Code<CR>')
vim.keymap.set('n', 'chat', ':Gen Chat<CR>')
```

### gen.nvim操作
- `Ctrl + a`: Gen起動
- `sum`: 選択したコードを要約 (Visual mode)
- `rev`: 選択したコードをレビュー (Visual mode)
- `chat`: チャットモード起動 (Normal mode)
- `q`: 終了
- `Ctrl + r`: リトライ

## Claude Code

### インストール
```bash
npm install -g @anthropic/claude-code
```

### 起動
```bash
claude
```

**注意:** 課金が必要

## その他の便利ツール

### avante.nvim
- Cursor AI IDEの体験をNeovimで再現

### NeoCodeium
- GitHub Copilotの代替
- 基本無料

## ワークフロー例

### 新機能開発
1. コメントを書く
2. GitHub Copilotで基本コード生成
3. 複雑な部分をgen.nvim + Ollamaで詳細設計
4. gen.nvimでコードレビュー

### デバッグ
1. 問題コードを選択
2. `Ctrl + a`でOllamaにバグ修正依頼
3. 必要に応じてClaude Codeで深い分析

## ファイル構成例
```
~/.config/nvim/
├── init.lua
└── lua/
    ├── keymaps.lua
    └── plugins/
        └── gen.lua
```
