# 外部 API を呼ぶときの作法 - 実演環境とコマンドのまとめ

動画「【リトライすれば直ると思っていませんか】外部 API を呼ぶときの作法」で使った実演環境とコマンドです。
`demo/` の Dockerfile で、わざと不安定にした上流 API（`upstream.js`、:4000）と実演スクリプトが入った使い捨てコンテナができます。上流（upstream）は「自分が呼びに行く先のサーバー」の意味で、nginx や Envoy の upstream と同じ使い方です。

## 実演環境を作る

```sh
cd demo && docker build -t resilience-demo . && docker run -it --rm --hostname demo --ulimit nofile=1024:1024 resilience-demo
```

上流 API のエンドポイント:

| パス | 動き |
|---|---|
| `GET /ok` | すぐ 200 |
| `GET /work` | 200ms 待って 200（プールの実演） |
| `GET /slow` | 5 秒待って 200（タイムアウトの実演） |
| `GET /flaky` | 3 回に 2 回は 503 + `Retry-After: 1`（リトライの実演） |
| `POST /pay` | 決済の真似。`Idempotency-Key` があれば同じ結果を返す |
| `GET /charges` | 作られた決済の一覧 |
| `GET /peak` | 前回以降の最大同時接続数 |

## 第 2 章 タイムアウト

```sh
curl --max-time 2 localhost:4000/slow; echo "exit=$?"            # 全体 2 秒。終了コード 28
curl --connect-timeout 1 http://10.255.255.1/; echo "exit=$?"    # 接続 1 秒
node -e 'fetch("http://localhost:4000/slow",{signal:AbortSignal.timeout(2000)}).catch(e=>console.log(e.name))'   # TimeoutError
```

Node の `http.request` は `timeout` オプション（無応答時間）と `socket.setTimeout`。DB クライアントは接続・クエリ・プール取得の 3 つに上限を付ける。連鎖する呼び出しは、全体の締め切りから残り時間を下流に渡す。

## 第 3 章 リトライ（`demo/retry.js`）

```js
const RETRY_STATUS = new Set([502, 503, 504, 429]);
async function withRetry(fn, { retries = 4, base = 200, max = 2000 } = {}) {
  for (let attempt = 1; ; attempt++) {
    try { return await fn(attempt); }
    catch (e) {
      if (attempt > retries || !e.retryable) throw e;
      const backoff = Math.min(max, base * 2 ** (attempt - 1));          // 指数バックオフ
      const wait = Math.round(backoff / 2 + Math.random() * backoff / 2); // ジッター
      await new Promise((r) => setTimeout(r, wait));
    }
  }
}
```

| 失敗 | リトライ | 理由 |
|---|---|---|
| 接続失敗、503、429、502、504 | する | 一時的 |
| タイムアウト | 冪等なら | 結果不明 |
| 400、401、403、404、422 | しない | 送り方の問題 |
| 500 | 慎重に | 直らないことが多い |

`Retry-After` があればその秒数を優先する。回数は 3〜5 回、全体の締め切りも守る。リトライ予算（全要求の 10% まで、など）で総量を絞る。

## 第 4 章 冪等性

```sh
curl -X POST -H "Idempotency-Key: order-42" -d '{"amount":500}' localhost:4000/pay   # {"id":"ch_1",...}
curl -X POST -H "Idempotency-Key: order-42" -d '{"amount":500}' localhost:4000/pay   # 同じ id、replayed: true
curl -X POST -d '{"amount":500}' localhost:4000/pay                                    # 鍵なしは毎回新しい id
curl localhost:4000/charges | jq '{count, ids: [.charges[].id]}'
```

サーバー側の要点（`demo/upstream.js` は Map で簡略化）:

- 鍵と結果の保存は、本体の書き込みと同じトランザクションで行う
- 鍵カラムにユニーク制約を付け、同時に 2 本来ても 1 本しか通らないようにする
- 同じ鍵で本文が違えば 422
- 鍵にも TTL（24 時間など）
- 「少なくとも 1 回」配信 + 冪等な受け手 = 実質ちょうど 1 回

## 第 5 章 コネクションと fd（`demo/pool.js`、`demo/fdtest.js`）

```js
const agent = new http.Agent({ keepAlive: true, maxSockets: 5 });   // 相手ごとの同時接続の上限
http.get({ host, port, path, agent }, cb);
```

```sh
node pool.js 0    # 制限なし: 相手は 20 本同時に受ける
node pool.js 2    # 2 本: 相手が見る同時接続は 2、全体は 10 倍かかる
ulimit -n                           # fd の上限（既定 1024 が多い）
ls /proc/$(pgrep -x node | head -1)/fd | wc -l    # 使用中の fd 数
lsof -p <pid> | grep -c TCP         # そのうち TCP 接続
ulimit -n 30; node fdtest.js 50     # 12 本目あたりで EMFILE。使い捨てコンテナの中で。手元のシェルで打つと戻せず、開き直すまで普通のコマンドも失敗する
```

本番の目安: `ulimit -n` は systemd の `LimitNOFILE=65536` などで上げる。閉じ忘れ（応答を読み切らない、エラー時に閉じない）を fd 数の推移で監視する。

## 第 6 章 全体を守る

| 型 | 何をするか |
|---|---|
| サーキットブレーカー | 失敗が続いたら一定時間、呼ばずに即エラー |
| バルクヘッド | 相手ごとにプール・スレッドを分ける |
| フェイルファスト | 前提条件を先に確かめて即失敗 |
| 負荷制限 | 捌けない分は 429 で断る |

計測: 相手のレイテンシは p99、リトライ回数と成功率、fd と接続数（上限の 8 割で警告）。
