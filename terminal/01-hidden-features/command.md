# ターミナルの隠し機能 コマンド・ショートカット集

## 1. コマンド再利用 (`!!`, `!$`, `!^`, `^old^new^`)

| ショートカット/コマンド | 動作 |
|---|---|
| `!!` | 直前のコマンド全体を展開 |
| `!$` | 直前のコマンドの最後の引数を展開 |
| `!^` | 直前のコマンドの最初の引数を展開 |
| `^old^new^` | 直前のコマンドの `old` を `new` に置き換えて即実行 |

```bash
# よくある使い方
sudo !!                    # 直前のコマンドをsudoで再実行
mkdir -p /some/deep/path
cd !$                      # 上のコマンドのパスにcd

# タイポの一発修正
git statsu
^statsu^status^            # → git status
```

## 2. ブレース展開 `{a,b,c}`

```bash
# ディレクトリの一括作成
mkdir -p src/{components,hooks,utils,types,constants}

# ファイルのリネーム（拡張子変更）
mv config.{yaml,yml}

# 連番ファイルの一括作成
touch file_{1..5}.txt

# アルファベット連番
echo {a..z}

# +α: バックアップトリック（空文字 と .bak の2展開）
cp config.yml{,.bak}
# → cp config.yml config.yml.bak と同じ
```

## 3. ヒアストリング `<<<`

```bash
# echo "..." | command を <<< で置き換える
grep -o "World" <<< "Hello World"
tr a-z A-Z <<< "$variable"

# bc（電卓）と組み合わせる
bc <<< "scale=2; 100/3"          # → 33.33
bc -l <<< "sqrt(2)"              # → 1.41421356237309504880

# JSON変数を jq に流す
json='{"name":"claude","version":"4.7"}'
jq '.name' <<< "$json"           # → "claude"

# +α: read で配列分割（zsh は -A、配列は1始まり）
read -A parts <<< "alpha beta gamma"
echo $parts[2]                    # → beta
```

`<<<` は1行限定。複数行を流すときは `<<EOF` のヒアドキュメントを使う。

## 4. シェルの行編集を Vim 風に (`set -o vi`)

zsh の行編集はデフォルトで Emacs キーバインド（6章のショートカットはすべて Emacs 由来）。`set -o vi` で Vim 風に切り替えられる。

```bash
# ~/.zshrc に追記
set -o vi

# 元の Emacs モードに戻す
set -o emacs
```

| キー（ノーマルモード時） | 動作 |
|---|---|
| `h` / `l` | 1文字 左 / 右 |
| `0` / `$` | 行頭 / 行末 |
| `w` / `b` | 単語単位で進む / 戻る |
| `dw` / `dd` | 単語 / 行 を削除 |
| `x` | カーソル位置の1文字を削除 |
| `u` | 直前の操作を取り消し |
| `i` | 入力モードに戻る |

## 5. プロセス置換 `<(command)` / `>(command)`

```bash
# 読み出し側 <(...) - コマンドの出力をファイルとして扱う
diff <(ls dir1) <(ls dir2)
diff <(sort file1.txt) <(sort file2.txt)
diff <(ssh server cat /etc/nginx/nginx.conf) nginx.conf

# +α: 書き込み側 >(...) - コマンドの入力をファイルとして扱う
./deploy.sh | tee \
  >(grep ERROR > errors.log) \
  >(grep WARN > warns.log) \
  > all.log
```

## 6. カーソル移動・行編集ショートカット

| キー | 動作 |
|------|------|
| `Ctrl+A` | 行頭に移動 |
| `Ctrl+E` | 行末に移動 |
| `Ctrl+W` | 直前の単語を削除 |
| `Ctrl+U` | 行全体を削除 |
| `Ctrl+K` | カーソルより後ろを全削除 |
| `Ctrl+Y` | 削除した内容を貼り付け |
| `Alt+B` | 単語単位で左へ移動 |
| `Alt+F` | 単語単位で右へ移動 |
| **`Alt+.`** | **直前コマンドの最後の引数を挿入（連打で過去に遡れる）** |
| **`Ctrl+T`** | **カーソル位置の文字と直前の文字を入れ替え** |

## 7. ディレクトリ移動 (`cd -`, `pushd`/`popd`)

```bash
# 直前のディレクトリに戻る
cd -

# ディレクトリスタックに積んで移動
pushd /var/log
pushd /etc/nginx

# スタックを確認
dirs

# スタックから取り出して戻る
popd

# +α: pushd 引数なし → スタックトップ2つを入れ替え
pushd

# +α: zsh で cd を自動的に pushd 化
echo 'setopt auto_pushd' >> ~/.zshrc
```

## 8. tee - 出力の分岐

```bash
# 画面とファイルへ同時出力
./script.sh | tee output.log

# 追記モード
./script.sh | tee -a output.log

# stderr も含めて保存
./script.sh 2>&1 | tee output.log

# 日時付きログファイル名
./deploy.sh | tee "deploy_$(date +%Y%m%d_%H%M%S).log"

# +α: sudo tee で root 所有ファイルに書き込む
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts
```

## 9. バックグラウンド管理 (`Ctrl+Z`, `fg`/`bg`, `jobs`, `disown`)

| コマンド | 動作 |
|---|---|
| `Ctrl+Z` | 実行中のプロセスを一時停止 |
| `fg` | 停止中のジョブをフォアグラウンドに戻す |
| `fg %2` | 番号指定でジョブに戻る |
| `bg` | 停止中のジョブをバックグラウンドで再開 |
| `jobs` | バックグラウンドのジョブ一覧を表示 |
| **`disown`** | **直前のバックグラウンドジョブをシェル終了時の SIGHUP から切り離す（SSH切断対応）** |

```bash
./long_build.sh &       # バックグラウンド起動
disown                  # SSH切断後も生き続ける
```

## 10. fc - コマンドの修正・再実行

```bash
# 直前のコマンドをエディタで修正して再実行
fc

# 履歴一覧を表示
fc -l
```
