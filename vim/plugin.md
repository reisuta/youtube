# Vimプラグインガイド

---

## 🎯 プラグインマネージャー vim-plug

### インストール方法

```bash
# Vim用
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Neovim用
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

### 基本的な使い方

```vim
call plug#begin()
Plug 'プラグイン名'
call plug#end()
```

---

## 📁 NERDTree 操作方法

<table>
<tr>
<td width="50%">

### 基本操作

| キー | 機能 |
|------|------|
| `?` | ヘルプ表示 |
| `o` / `Enter` | ファイル/ディレクトリを開く |
| `x` | 親ディレクトリを閉じる |
| `go` | ファイルを開く（カーソルはツリーのまま） |

</td>
<td width="50%">

### ファイル表示

| キー | 機能 |
|------|------|
| `t` | タブでファイルを開く |
| `T` | タブで開く（タブにフォーカスしない） |
| `i` | 水平分割でファイルを開く |
| `gi` | 水平分割で開く（カーソルはツリーのまま） |
| `s` | 垂直分割でファイルを開く |
| `gs` | 垂直分割で開く（カーソルはツリーのまま） |

</td>
</tr>
</table>

<table>
<tr>
<td width="50%">

### ディレクトリ操作

| キー | 機能 |
|------|------|
| `C` | ツリーのルートを選択したディレクトリにする |
| `u` | ツリーのルートを上の階層にする |
| `U` | ツリーのルートを上の階層にする（開いた状態を保持） |
| `r` | 選択したディレクトリを再読み込み |
| `R` | ツリー全体を再読み込み |

</td>
<td width="50%">

### ファイル操作

| キー | 機能 |
|------|------|
| `m` | ファイル操作メニューを表示 |
| `I` | 隠しファイルの表示/非表示切り替え |
| `B` | ブックマーク表示の有効/無効切り替え |

</td>
</tr>
</table>

### ファイル操作メニュー（`m`キー後）

| キー | 機能 |
|------|------|
| `a` | ファイル/ディレクトリを作成 |
| `m` | ファイル/ディレクトリを移動/リネーム |
| `d` | ファイル/ディレクトリを削除 |
| `c` | ファイル/ディレクトリをコピー |

---

## 📝 .vimrc サンプル設定

```vim
call plug#begin()
Plug 'preservim/nerdtree'
Plug 'Shougo/unite.vim'
Plug 'tpope/vim-commentary'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'simeji/winresizer'
Plug 'nathanaelkane/vim-indent-guides'
call plug#end()

" 基本設定
syntax on
set number
set relativenumber
set tabstop=2
set shiftwidth=2
set expandtab

" キーマッピング
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <silent> un :<C-u>Unite buffer<CR>
nnoremap <silent> unf :<C-u>Unite file<CR>

let g:indent_guides_enable_on_vim_startup = 1
```

---

## 🚀 init.vim サンプル設定 (Neovim)

```vim
call plug#begin()
Plug 'preservim/nerdtree'
Plug 'tpope/vim-commentary'
" Neovim専用プラグイン
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'akinsho/toggleterm.nvim'
Plug 'lewis6991/gitsigns.nvim'
call plug#end()

syntax on
set number
set relativenumber

" キーマッピング
let mapleader = " "
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap fff <cmd>Telescope find_files<cr>
nnoremap fgr <cmd>Telescope live_grep<cr>

" Lua設定
lua << EOF
require('telescope').setup{}
require('toggleterm').setup{
  size = 20,
  direction = 'horizontal',
}
require('gitsigns').setup{
  current_line_blame = true,
}
EOF
```

---

## 💡 プラグイン導入のコツ

<table>
<tr>
<td width="50%">

### ✅ 推奨事項
- **段階的導入**: 一つずつ試す
- **定期的整理**: 使わないプラグインは削除
- **ドキュメント確認**: 公式ドキュメントを読む
- **定期更新**: `:PlugUpdate` で最新化

</td>
<td width="50%">

### ❌ 避けるべきこと
- **大量同時導入**: 問題の特定が困難
- **重複機能**: 似た機能のプラグインを複数
- **設定放置**: インストール後の設定を怠る

</td>
</tr>
</table>

---

## 🎯 プラグイン分類

| カテゴリ | Vim系 | Neovim系 |
|----------|-------|----------|
| **ファイラー** | NERDTree, Fern | nvim-tree |
| **検索** | Unite.vim, ctrlp.vim | telescope.nvim |
| **補完** | YouCompleteMe | coc.nvim, nvim-lsp |
| **Git** | vim-fugitive | gitsigns.nvim |
| **ターミナル** | vim-quickrun | toggleterm.nvim |
| **見た目** | vim-airline | lualine.nvim |

---

## 📚 参考リンク

- [vim-plug GitHub](https://github.com/junegunn/vim-plug)
- [NERDTree GitHub](https://github.com/preservim/nerdtree)  
- [telescope.nvim GitHub](https://github.com/nvim-telescope/telescope.nvim)
- [coc.nvim GitHub](https://github.com/neoclide/coc.nvim)

---

