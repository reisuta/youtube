#!/usr/bin/env bash
# 動画の実演用リポジトリを /tmp/lazygit-demo に作り直す。
#   bash demo/setup.sh <scenario>
# scenario:
#   base     6 コミットの Ruby の小さなアプリ（作業ツリーはきれい）
#   read     AI が出した 1 つの大きな差分（3 ファイル、関心事が 3 つ混ざる）を未ステージで置く
#   split    read と同じ（分ける実演用）
#   fix      「あとで直す」用: 3 コミット積んだ後に 1 つ目のコミットへの修正が未ステージで残っている
#   rebase   雑な 5 コミット（typo・WIP・順番違い）を積んだ feature ブランチ
#   undo     間違って drop / reset した直後の状態（reflog に残っている）
#   branch   feature が 2 本と stash が 1 つある状態
# 触るのは /tmp/lazygit-demo だけ。実ホーム・実リポジトリ・global 設定には触れない。
# lazygit は demo/config.yml を LG_CONFIG_FILE で読む（起動時のポップアップと更新確認を切り、アイコンを出す）。
# 実機の config.yml は読まないが、状態ファイル state.yml（最近開いたリポジトリなど）は本来の設定ディレクトリに書かれる。
# 必要なもの: git 2.28 以上、lazygit 0.55 以上、ruby（テスト用）。
set -euo pipefail
D=/tmp/lazygit-demo
rm -rf "$D"
mkdir -p "$D"/{lib,test}
cd "$D"
git init -q -b main
git config user.name "demo"
git config user.email "demo@example.com"
git config core.pager cat
git config rerere.enabled true

c() { git add -A && GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" git commit -q -m "$1"; }
sedi() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }

# ---- base: Ruby の小さなアプリと 6 コミット ----
cat > app.rb <<'EOF'
require_relative "lib/format"
require_relative "lib/tax"

def total(items)
  items.sum { |i| i[:price] * i[:qty] }
end

def receipt(items)
  subtotal = total(items)
  tax = calculate_tax(subtotal)
  format_yen(subtotal + tax)
end
EOF
cat > lib/format.rb <<'EOF'
def format_yen(n)
  "#{n.to_s.reverse.scan(/\d{1,3}/).join(",").reverse} yen"
end
EOF
cat > lib/tax.rb <<'EOF'
def calculate_tax(price)
  (price * 0.08).round
end
EOF
cat > test/app_test.rb <<'EOF'
require "minitest/autorun"
require_relative "../app"

class AppTest < Minitest::Test
  def test_total
    assert_equal 300, total([{ price: 100, qty: 3 }])
  end

  def test_receipt
    assert_equal "324 yen", receipt([{ price: 100, qty: 3 }])
  end
end
EOF
printf '.bundle/\n*.log\n' > .gitignore
c "initial: receipt app"              "2026-09-01T09:00:00"
echo '# receipt' > README.md;                                   c "docs: add README"          "2026-09-02T09:00:00"
sedi 's/0.08/0.10/' lib/tax.rb; sedi 's/324 yen/330 yen/' test/app_test.rb; c "tax: 8% -> 10%" "2026-09-03T09:00:00"
cat >> lib/format.rb <<'EOF'

def format_date(t)
  t.strftime("%Y-%m-%d")
end
EOF
c "format: add format_date"           "2026-09-04T09:00:00"
sedi 's/def receipt(items)/def receipt(items, discount = 0)/; s/subtotal = total(items)/subtotal = total(items) - discount/' app.rb
c "receipt: add discount"             "2026-09-05T09:00:00"
echo '- run: ruby test/app_test.rb' >> README.md;               c "docs: how to test"         "2026-09-06T09:00:00"

# ---- AI が一度に出した「大きな差分」: 関心事が 3 つ混ざる（read / split） ----
big_diff() {
  # 1) 値引きの下限（本命の変更。1 行の置き換え = diff では - と + の 2 行）
  sedi 's/subtotal = total(items) - discount/subtotal = [total(items) - discount, 0].max/' app.rb
  # 2) ついでのコメント追加（同じ hunk に混ざる。分ける実演用）
  sedi 's/^def receipt(items, discount = 0)/# returns the receipt as a yen string\
def receipt(items, discount = 0)/' app.rb
  # 3) 関係ないファイルへのデバッグ出力（消すべき変更）
  sedi 's/def calculate_tax(price)/def calculate_tax(price)\n  puts "tax for #{price}"/' lib/tax.rb
  # 4) テストの追加（本命に付随）
  cat >> test/app_test.rb <<'EOF'

class DiscountTest < Minitest::Test
  def test_discount_floor
    assert_equal "0 yen", receipt([{ price: 100, qty: 1 }], 500)
  end
end
EOF
}

case "${1:-base}" in
  base) ;;
  read|split) big_diff ;;
  fix)
    # 3 コミット積んだ後、1 つ目（format_date）に typo の修正が必要になった
    sedi 's/%Y-%m-%d/%Y-%m-%d %H:%M/' lib/format.rb; c "format: date with time" "2026-09-07T09:00:00"
    echo '- ruby 3.3' >> README.md;                     c "docs: ruby version"    "2026-09-08T09:00:00"
    sedi 's/0.10/0.1/' lib/tax.rb;                      c "tax: simplify literal" "2026-09-09T09:00:00"
    sedi 's/%H:%M/%H:%M:%S/' lib/format.rb              # ← これは "format: date with time" に混ぜたい修正
    ;;
  rebase)
    git switch -q -c feature/coupon
    echo 'def coupon(code) = code == "SAVE10" ? 10 : 0' > lib/coupon.rb;   c "coupon: add coupon()"     "2026-09-07T09:00:00"
    echo '# coupn'  >> README.md;                                          c "docs: coupn"              "2026-09-07T10:00:00"
    sedi 's/# coupn/# coupon: SAVE10/' README.md;                          c "fix typo"                 "2026-09-07T11:00:00"
    echo 'puts "debug"' >> lib/coupon.rb;                                  c "WIP"                      "2026-09-07T12:00:00"
    sedi '/puts "debug"/d' lib/coupon.rb; echo 'require_relative "lib/coupon"' >> app.rb; c "coupon: wire into app" "2026-09-07T13:00:00"
    ;;
  undo)
    git switch -q -c feature/coupon
    echo 'def coupon(code) = code == "SAVE10" ? 10 : 0' > lib/coupon.rb;   c "coupon: add coupon()"     "2026-09-07T09:00:00"
    echo 'require_relative "lib/coupon"' >> app.rb;                        c "coupon: wire into app"    "2026-09-07T10:00:00"
    git reset -q --hard HEAD~2      # 間違って 2 コミット消した直後。reflog には残っている
    ;;
  branch)
    git switch -q -c feature/coupon
    echo 'def coupon(code) = code == "SAVE10" ? 10 : 0' > lib/coupon.rb;   c "coupon: add coupon()"     "2026-09-07T09:00:00"
    git switch -q main
    git switch -q -c fix/format-nil
    sedi 's/def format_yen(n)/def format_yen(n)\n  return "0 yen" if n.nil?/' lib/format.rb; c "format: nil guard" "2026-09-07T10:00:00"
    git switch -q main
    echo '# TODO: rewrite' >> README.md; git stash push -q -m "readme note"
    ;;
  *) echo "unknown scenario: $1" >&2; exit 1 ;;
esac
