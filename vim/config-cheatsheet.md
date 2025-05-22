# Vim基本コマンド・設定一覧表

## 基本設定（set コマンド）

| 設定 | 説明 | 例 |
|------|------|-----|
| `number` | 行番号を表示 | `set number` |
| `relativenumber` | カーソル位置からの相対行番号を表示 | `set relativenumber` |
| `cursorline` | カーソル行をハイライト | `set cursorline` |
| `cursorcolumn` | カーソル列をハイライト | `set cursorcolumn` |
| `showmatch` | 対応する括弧をハイライト | `set showmatch` |
| `laststatus` | ステータスラインの表示設定 | `set laststatus=2` |
| `showmode` | 現在のモードを表示 | `set showmode` |
| `hlsearch` | 検索結果をハイライト | `set hlsearch` |
| `incsearch` | インクリメンタルサーチ | `set incsearch` |
| `expandtab` | タブをスペースに変換 | `set expandtab` |
| `tabstop` | タブを表示する幅 | `set tabstop=4` |
| `shiftwidth` | インデントの幅 | `set shiftwidth=2` |
| `autoindent` | 自動インデント | `set autoindent` |
| `clipboard` | システムクリップボードと連携 | `set clipboard=unnamed` |
| `visualbell` | ビープ音を無効化 | `set visualbell` |
| `nocompatible` | Vi互換モードをオフ | `set nocompatible` |

## シンタックス・ファイルタイプ設定

| 設定 | 説明 | 例 |
|------|------|-----|
| `syntax on` | シンタックスハイライトを有効化 | `syntax on` |
| `filetype plugin indent on` | ファイルタイプ検出、プラグイン、インデントを有効化 | `filetype plugin indent on` |

## 変数設定（let コマンド）

| 設定 | 説明 | 例 |
|------|------|-----|
| `mapleader` | Leaderキーの設定 | `let mapleader = ","` |

## マッピングコマンド

| コマンド | 説明 | 例 |
|---------|------|-----|
| `map` | 再帰的マッピング（全モード） | `map j k` |
| `nmap` | ノーマルモード用の再帰的マッピング | `nmap j k` |
| `imap` | インサートモード用の再帰的マッピング | `imap jj <ESC>` |
| `vmap` | ビジュアルモード用の再帰的マッピング | `vmap < <gv` |
| `nnoremap` | ノーマルモード用の非再帰的マッピング | `nnoremap j gj` |
| `inoremap` | インサートモード用の非再帰的マッピング | `inoremap jj <ESC>` |
| `vnoremap` | ビジュアルモード用の非再帰的マッピング | `vnoremap < <gv` |
| `cnoremap` | コマンドラインモード用の非再帰的マッピング | `cnoremap <C-p> <Up>` |
| `tnoremap` | ターミナルモード用の非再帰的マッピング | `tnoremap <Esc> <C-\><C-n>` |

## Leaderキーマッピング例

| マッピング | 説明 | 例 |
|-----------|------|-----|
| `<Leader>w` | ファイル保存 | `nnoremap <Leader>w :w<CR>` |
| `<Leader>q` | 終了 | `nnoremap <Leader>q :q<CR>` |
| `<Leader>h` | 検索ハイライトを消す | `nnoremap <Leader>h :nohlsearch<CR>` |

## 便利なマッピング例

| マッピング | 説明 | 例 |
|-----------|------|-----|
| `jj` | ESCキー（インサートモード脱出） | `inoremap jj <ESC>` |
| `j`/`k` | 表示行単位で移動 | `nnoremap j gj` `nnoremap k gk` |
| `<C-w>移動` | ウィンドウ間移動を簡略化 | `nnoremap <C-h> <C-w>h` |

## ユーザー定義コマンド

| 構文 | 説明 | 例 |
|------|------|-----|
| `command!` | ユーザー定義コマンド（上書き） | `command! CommandName action` |

## 便利なユーザー定義コマンド例

| コマンド | 説明 | 例 |
|---------|------|-----|
| `Vimrc` | 設定ファイルを開く | `command! Vimrc :e $MYVIMRC` |
| `ReloadVimrc` | 設定ファイルを再読み込み | `command! ReloadVimrc :source $MYVIMRC` |

## autocmd（自動コマンド）

| 構文 | 説明 | 例 |
|------|------|-----|
| `autocmd` | 特定のイベントで自動実行 | `autocmd Event Pattern Command` |
| `augroup`/`augroup END` | autocmdのグループ化 | `augroup group_name` ~ `augroup END` |
| `autocmd!` | グループ内の既存コマンドをクリア | `autocmd!` |

## 主なautocmdイベント

| イベント | 説明 |
|---------|------|
| `FileType` | ファイルタイプ検出時 |
| `BufWritePre` | ファイル保存前 |

## autocmd例

| 用途 | 例 |
|------|-----|
| ファイルタイプ別設定 | `autocmd FileType python setlocal tabstop=4 shiftwidth=4` |
| ファイルタイプ別設定 | `autocmd FileType javascript,html,css setlocal tabstop=2 shiftwidth=2` |
| マークダウンでスペルチェック | `autocmd FileType markdown setlocal spell` |
| 保存時に空白削除 | `autocmd BufWritePre * :%s/\s\+$//e` |

## その他のコマンド

| コマンド | 説明 | 例 |
|---------|------|-----|
| `setlocal` | カレントバッファにのみ設定を適用 | `setlocal tabstop=4` |

## .vimrcテンプレート

```vim
" 基本設定 ------------------------------
set nocompatible              " Vi互換モードをオフ
filetype plugin indent on     " ファイルタイプ検出、プラグイン、インデントを有効化
set visualbell                " ビープ音無効化
syntax on                     " シンタックスハイライト有効
set clipboard=unnamed

" UI設定 --------------------------------
set nonumber                  " 行番号非表示
set norelativenumber          " 相対行番号非表示
set cursorline                " カーソル行ハイライト
set cursorcolumn              " カーソル列ハイライト
set showmatch                 " 対応する括弧をハイライト
set laststatus=2              " 常にステータスラインを表示
set showmode                  " 現在のモードを表示

" 検索設定 ------------------------------
set hlsearch                  " 検索結果をハイライト
set incsearch                 " インクリメンタルサーチ

" 編集設定 ------------------------------
set autoindent                " 自動インデント
set expandtab                 " タブをスペースに変換
set tabstop=4                 " タブ幅
set shiftwidth=2              " インデント幅

" LeaderキーとLEADERマッピング -------------
let mapleader = ","           " Leaderキーをカンマに設定
nnoremap <Leader>w :w<CR>     " ,wで保存
nnoremap <Leader>q :q<CR>     " ,qで終了
nnoremap <Leader>h :nohlsearch<CR> " ,hでハイライト消去

" 便利なマッピング -----------------------
inoremap jj <ESC>             " jjでESC
" ウィンドウ間の移動を簡単に
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" コマンド定義 ---------------------------
command! Vimrc :e $MYVIMRC    " :Vimrcで設定ファイルを開く
command! ReloadVimrc :source $MYVIMRC " 設定再読み込み

" ファイルタイプ別設定 -------------------
augroup filetype_settings
  autocmd!
  autocmd FileType python setlocal tabstop=4 shiftwidth=4
  autocmd FileType javascript,html,css setlocal tabstop=2 shiftwidth=2
  autocmd FileType markdown setlocal spell " マークダウンはスペルチェック有効
augroup END
```

## コマンドモードでの設定変更

| 用途 | コマンド例 |
|------|-----------|
| 設定値の確認 | `:set tabstop?` |
| 一時的な設定変更 | `:set tabstop=2` |
| 設定のオン/オフ切替 | `:set number!` |
| 設定をオフにする | `:set nonumber` `:set norelativenumber` |
| マッピングの削除 | `:unmap j` |
| 一時的なマッピング | `:nnoremap j k` |
| 検索ハイライト消去 | `:nohlsearch` |
| コマンド一時定義 | `:command! Test echo "テスト"` |
| autocmd一時定義 | `:autocmd BufWritePre * :%s/\s\+$//e` |

