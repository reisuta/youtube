#!/usr/bin/env bash
# 動画の実演を再現するためのデモ用リポジトリを /tmp/git-demo に作り直す。
#   bash demo/setup.sh <scenario>
# scenario: base diff_read log_search blame add_p fixup worktree reflog restore bisect rerere
# 触るのは /tmp/git-demo と /tmp/git-demo-feature だけ（実行のたびに削除して作り直す）。
# 必要なもの: git 2.28 以上（init -b）、ruby（bisect シナリオの test.rb 用）。
set -euo pipefail

DEMO=/tmp/git-demo
rm -rf "$DEMO" /tmp/git-demo-feature
mkdir -p "$DEMO"
cd "$DEMO"
git init -q -b main
git config user.name "reisuta"
git config user.email "reisuta@example.com"
git config core.pager cat
git config color.ui always
git config init.defaultBranch main

c() { git add -A && git commit -q -m "$1" && [ -n "${2:-}" ] && git tag -f "$2" >/dev/null || true; }
# macOS(BSD) と Linux(GNU) の両方で動く in-place sed
sedi() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }

# ---- base: Ruby の小さなアプリと 6 コミットの履歴 ----
cat > app.rb <<'EOF'
require_relative "lib/format"

def calculate_tax(price)
  (price * 0.1).round
end

def total(items)
  sum = items.sum { |i| i[:price] }
  sum + calculate_tax(sum)
end

puts format_yen(total([{ name: "book", price: 1200 }, { name: "pen", price: 300 }]))
EOF
mkdir -p lib
cat > lib/format.rb <<'EOF'
def format_yen(n)
  "#{n.to_s.reverse.scan(/\d{1,3}/).join(",").reverse} yen"
end
EOF
printf '# demo\n\nsmall ruby app for git demo\n' > README.md
c "initial: app skeleton"
sedi 's/(price \* 0.1).round/(price * 0.10).round/' app.rb
c "tax: use explicit rate literal"
printf '\ndef discount(price, rate)\n  (price * (1 - rate)).round\nend\n' >> lib/format.rb
c "format: add discount helper"
sedi 's/"book", price: 1200/"book", price: 1500/' app.rb
c "app: update sample price"
printf '\n## usage\n\n    ruby app.rb\n' >> README.md
c "docs: usage" v1.0
sedi 's/sum + calculate_tax(sum)/sum + calculate_tax(sum) # tax included/' app.rb
c "app: annotate total"

case "${1:-base}" in
  base) ;;

  diff_read)
    # AI が関数を末尾へ移動し、変数名を変え、1 行だけ意味を変えた未コミットの変更
    cat > app.rb <<'EOF'
require_relative "lib/format"

def total(items)
  subtotal = items.sum { |i| i[:price] }
  subtotal + calculate_tax(subtotal) # tax included
end

puts format_yen(total([{ name: "book", price: 1500 }, { name: "pen", price: 300 }]))

def calculate_tax(price)
  (price * 0.08).round
end
EOF
    ;;

  log_search)
    # calculate_tax → apply_tax に改名し、その後 2 回手が入る
    sedi 's/calculate_tax/apply_tax/g' app.rb
    c "refactor: rename calculate_tax to apply_tax"
    sedi 's/(price \* 0.10).round/(price * TAX_RATE).round/' app.rb
    sedi '1a\
TAX_RATE = 0.10
' app.rb
    c "tax: extract TAX_RATE constant"
    sedi 's/def apply_tax(price)/def apply_tax(price, rate = TAX_RATE)/; s/(price \* TAX_RATE).round/(price * rate).round/' app.rb
    c "tax: allow rate override"
    ;;

  blame)
    # AI フォーマッタが全行を再インデント（意味は変えない）
    git config user.name "ai-formatter"
    sedi 's/^  /    /' app.rb lib/format.rb
    c "style: reformat with 4-space indent"
    git config user.name "reisuta"
    ;;

  add_p)
    # バグ修正（税率の丸め）とリファクタリング（変数名）が 1 ファイルに混在した未コミット変更
    cat > app.rb <<'EOF'
require_relative "lib/format"

def calculate_tax(price)
  (price * 0.10).floor
end

def total(items)
  subtotal = items.sum { |i| i[:price] }
  subtotal + calculate_tax(subtotal) # tax included
end

puts format_yen(total([{ name: "book", price: 1500 }, { name: "pen", price: 300 }]))
EOF
    ;;

  fixup)
    # 履歴を作り直し、HEAD~2 の "format: add discount helper" に typo（discont）を仕込む
    git reset -q --hard HEAD~4
    printf '\ndef discont(price, rate)\n  (price * (1 - rate)).round\nend\n' >> lib/format.rb
    c "format: add discount helper"
    sedi 's/"book", price: 1200/"book", price: 1500/' app.rb
    c "app: update sample price"
    printf '\n## usage\n\n    ruby app.rb\n' >> README.md
    c "docs: usage"
    git config rebase.autosquash true
    ;;

  worktree)
    git branch feature/login
    ;;

  reflog) ;;

  restore)
    sedi 's/0.10/0.08/' app.rb
    c "tax: lower rate (experiment)"
    sedi 's/"pen", price: 300/"pen", price: 350/' app.rb
    c "app: pen price"
    ;;

  bisect)
    # v1.0 以降に 16 コミット。11 番目で format_yen が壊れる。test.rb は成功 0 / 失敗 1
    cat > test.rb <<'EOF'
require_relative "lib/format"
expected = "1,980 yen"
actual = format_yen(1980)
if actual == expected
  puts "ok: #{actual}"
  exit 0
else
  puts "FAIL: expected #{expected}, got #{actual}"
  exit 1
end
EOF
    c "test: add format_yen test" v1.0
    for i in $(seq 1 16); do
      if [ "$i" -eq 11 ]; then
        sedi 's|scan(/\\d{1,3}/)|scan(/\\d{1,4}/)|' lib/format.rb
        c "format: tweak grouping regex"
      else
        printf '# note %s\n' "$i" >> README.md
        c "docs: note $i"
      fi
    done
    ;;

  rerere)
    git config rerere.enabled true
    git config rerere.autoupdate true
    git config merge.conflictStyle zdiff3
    git checkout -q -b feature
    sedi 's/(price \* 0.10).round/(price * 0.10).ceil/' app.rb
    c "feature: round tax up"
    git checkout -q main
    sedi 's/(price \* 0.10).round/(price * 0.10).floor/' app.rb
    c "main: round tax down"
    git checkout -q feature
    ;;

  *) echo "unknown scenario: $1" >&2; exit 1 ;;
esac

