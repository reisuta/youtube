# AI時代のGit中級テクニック10選 - コマンドと設定のまとめ

動画「【git add . しか知らない人へ】AIにコードを書かせるなら必須のGit中級テクニック10選」で紹介したコマンドと設定です。

## まず入れておく設定（global）

```sh
git config --global diff.algorithm histogram        # 差分の対応付けが直感的になる
git config --global merge.conflictStyle zdiff3      # コンフリクト表示に共通祖先が出る
git config --global rebase.autosquash true          # fixup コミットが rebase -i で自動整列
git config --global rerere.enabled true             # 解決したコンフリクトを記憶して再利用
git config --global rerere.autoupdate true          # 自動解決したファイルをステージまで
git config --global blame.ignoreRevsFile .git-blame-ignore-revs
```

## 第1章 読む

### 1. git diff を読む用にする

```sh
git diff --stat                              # まず量を把握する
git diff --color-moved=dimmed-zebra          # 移動しただけの行を暗くする
git diff --word-diff                         # 行内のどの単語が変わったか
git diff -w                                  # 空白だけの変更を無視
git diff --color-moved=dimmed-zebra -- app.rb   # ファイルを絞る
```

### 2. git log で「いつ変わったか」を探す

```sh
git log -S'calculate_tax' --oneline          # 出現回数が変わったコミット（追加・削除の瞬間）
git log -G'tax' --oneline                    # 差分に正規表現を含むコミット
git log -L :apply_tax:app.rb                 # 関数単位の変更履歴（差分付き）
git log --follow -p -- lib/format.rb         # ファイル名変更をまたいで追う
```

### 3. git blame を整形コミットで汚さない

```sh
git blame -w -M -C app.rb                    # 空白無視・移動・コピー追跡
echo <整形コミットのハッシュ> >> .git-blame-ignore-revs
git config blame.ignoreRevsFile .git-blame-ignore-revs
git blame app.rb                             # 以後は自動で読み飛ばす
```

## 第2章 分ける

### 4. git add -p で hunk 単位にステージする

```sh
git add -p                                   # y: ステージ / n: 飛ばす / s: 分割 / e: 手で編集 / q: 終了
git diff --cached                            # ステージした内容だけを確認
git commit -m "fix: ..."
git restore --staged -p                      # 間違えた hunk をステージから外す
```

### 5. git commit --fixup と autosquash

```sh
git commit --fixup <対象コミット>            # 対象宛ての修正コミットを積む
git rebase -i --autosquash <対象コミット>~1  # fixup が対象の直後に並び squash される
GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash <対象>~1   # エディタを開かずに実行
```

### 6. git worktree で並列作業

```sh
git worktree add ../repo-feature feature/login   # 隣のディレクトリに別ブランチをチェックアウト
git worktree add -b feature/test ../repo-test    # 新規ブランチを作りつつ追加
git worktree list
git worktree remove ../repo-feature
git worktree prune                               # 消えたディレクトリの登録を掃除
```

## 第3章 戻す

### 7. git reflog で復旧

```sh
git reflog                                   # HEAD の移動履歴
git reset --hard HEAD@{1}                    # 1 つ前の HEAD 位置へ戻す（未コミットの変更は消えるので先に stash か commit）
git branch rescue HEAD@{3}                   # ブランチとして拾っておく
# reflog の記録は既定で 90 日（reset などで到達できなくなった分は 30 日）残る。gc.reflogExpire / gc.reflogExpireUnreachable で変更できる
```

### 8. git restore で 1 ファイルだけ戻す

```sh
git restore app.rb                           # 作業ツリーの変更を捨てて HEAD に戻す（取り消せないので diff で確認してから）
git restore --source=HEAD~2 -- app.rb        # 2 コミット前の内容にする
git restore --staged app.rb                  # ステージだけ外す（作業ツリーは残る）
git restore -p app.rb                        # hunk 単位で選ぶ
```

### 9. git bisect run で原因コミットを自動特定

```sh
git bisect start HEAD v1.0                   # 壊れている点 正常だった点
git bisect run ruby test.rb                  # 0 なら good、1 なら bad として自動で二分探索
git bisect log                               # 経過
git bisect reset                             # 元の位置に戻る
```

`git bisect run` に渡すコマンドは、正常時に 0、異常時に 1〜127（125 を除く）を返せば何でもよい。テストランナーでも `grep -q` でもよい。

### 10. git rerere で同じコンフリクトを二度と解決しない

```sh
git config rerere.enabled true
git rerere status                            # 記録待ちのコンフリクト
git rerere diff                              # 記録された解決との差
git rerere forget <path>                     # 記録を消す
```

## 実演の再現

動画の実演は `demo/setup.sh <scenario>` で `/tmp/git-demo` に同じ状態を作れます。

```sh
bash demo/setup.sh bisect && cd /tmp/git-demo
git bisect start HEAD v1.0 && git bisect run ruby test.rb
```
