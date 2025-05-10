# curlの主要オプション一覧表

| オプション | 短縮形 | 説明 | 使用例 |
|----------|-------|------|-------|
| `--output` | `-o` | 出力をファイルに保存する | `curl -o weather.txt wttr.in/Tokyo` |
| `--location` | `-L` | リダイレクトを追跡する | `curl -L https://bit.ly/3S9Bhdx` |
| `--head` | `-I` | HTTPヘッダーのみを取得する | `curl -I wttr.in` |
| `--request` | `-X` | HTTPメソッドを指定する | `curl -X POST https://httpbin.org/post` |
| `--header` | `-H` | HTTPヘッダーを追加する | `curl -H "Content-Type: application/json" https://httpbin.org/headers` |
| `--data` | `-d` | POSTデータを送信する | `curl -d "name=value" https://httpbin.org/post` |
| `--verbose` | `-v` | 詳細情報を表示する | `curl -v wttr.in/Tokyo` |
| `--silent` | `-s` | 進行状況や警告を表示しない | `curl -s wttr.in?format=3` |
| `--include` | `-i` | レスポンスヘッダーも含めて表示する | `curl -i httpbin.org/headers` |
| `--fail` | `-f` | サーバーエラー時に出力を表示しない | `curl -f httpbin.org/status/200` |
| `--compressed` | | 圧縮されたレスポンスを要求する | `curl --compressed wttr.in` |
| `--max-time` | `-m` | 最大タイムアウト時間を指定する（秒） | `curl -m 10 wttr.in` |
| `--connect-timeout` | | 接続タイムアウト時間を指定する（秒） | `curl --connect-timeout 5 wttr.in` |
| `--retry` | | 指定回数リトライする | `curl --retry 3 wttr.in` |
| `--user-agent` | `-A` | ユーザーエージェントを指定する | `curl -A "Mozilla/5.0" httpbin.org/user-agent` |
| `--referer` | `-e` | リファラーを指定する | `curl -e "https://google.com" httpbin.org/headers` |
| `--output-dir` | | 出力先ディレクトリを指定する | `curl --output-dir ./ -O https://source.unsplash.com/random/800x600` |
| `--limit-rate` | | 転送速度を制限する | `curl --limit-rate 50K https://httpbin.org/bytes/1000000 -o test.bin` |
| `--json` | | JSONデータを送信する | `curl --json '{"name":"value"}' https://httpbin.org/post` |
| `--parallel` | | 複数のURLを並列に処理する | `curl --parallel wttr.in wttr.in/osaka wttr.in/kyoto` |
| `--trace` | | すべての送受信データをファイルに記録する | `curl --trace debug.txt https://httpbin.org/get` |
