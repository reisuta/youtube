# curlの主要オプション一覧表

| オプション | 短縮形 | 説明 | 使用例 |
|----------|-------|------|-------|
| `--output` | `-o` | 出力をファイルに保存する | `curl -o output.html https://example.com` |
| `--remote-name` | `-O` | リモートファイル名をそのまま使用する | `curl -O https://example.com/image.jpg` |
| `--location` | `-L` | リダイレクトを追跡する | `curl -L https://t.co/shorturl` |
| `--head` | `-I` | HTTPヘッダーのみを取得する | `curl -I https://example.com` |
| `--request` | `-X` | HTTPメソッドを指定する | `curl -X POST https://api.example.com` |
| `--header` | `-H` | HTTPヘッダーを追加する | `curl -H "Authorization: Bearer token" https://api.com` |
| `--data` | `-d` | POSTデータを送信する | `curl -d "name=value" https://api.example.com` |
| `--user` | `-u` | Basic認証を使用する | `curl -u username:password https://site.com` |
| `--verbose` | `-v` | 詳細情報を表示する | `curl -v https://example.com` |
| `--silent` | `-s` | 進行状況や警告を表示しない | `curl -s https://example.com` |
| `--include` | `-i` | レスポンスヘッダーも含めて表示する | `curl -i https://example.com` |
| `--fail` | `-f` | サーバーエラー時に出力を表示しない | `curl -f https://example.com` |
| `--compressed` | | 圧縮されたレスポンスを要求する | `curl --compressed https://example.com` |
| `--max-time` | `-m` | 最大タイムアウト時間を指定する（秒） | `curl -m 30 https://example.com` |
| `--connect-timeout` | | 接続タイムアウト時間を指定する（秒） | `curl --connect-timeout 10 https://example.com` |
| `--retry` | | 指定回数リトライする | `curl --retry 3 https://example.com` |
| `--cookie` | `-b` | クッキーを送信する | `curl -b "name=value" https://example.com` |
| `--cookie-jar` | `-c` | クッキーを保存する | `curl -c cookies.txt https://example.com` |
| `--user-agent` | `-A` | ユーザーエージェントを指定する | `curl -A "Mozilla/5.0" https://example.com` |
| `--referer` | `-e` | リファラーを指定する | `curl -e "https://google.com" https://example.com` |
| `--form` | `-F` | マルチパートフォームデータを送信する | `curl -F "file=@image.jpg" https://example.com` |
| `--upload-file` | `-T` | ファイルをアップロードする | `curl -T file.txt https://example.com` |
| `--proxy` | `-x` | プロキシを指定する | `curl -x http://proxy:8080 https://example.com` |
| `--insecure` | `-k` | SSL証明書の検証をスキップする | `curl -k https://example.com` |
| `--output-dir` | | 出力先ディレクトリを指定する | `curl --output-dir /downloads https://example.com` |
| `--range` | `-r` | ダウンロード範囲を指定する | `curl -r 0-1000 https://example.com/file` |
| `--limit-rate` | | 転送速度を制限する | `curl --limit-rate 100K https://example.com` |
| `--json` | | JSONデータを送信する | `curl --json '{"name":"value"}' https://api.com` |
| `--parallel` | | 複数のURLを並列に処理する | `curl --parallel https://site1.com https://site2.com` |
| `--trace` | | すべての送受信データをファイルに記録する | `curl --trace debug.txt https://example.com` |
