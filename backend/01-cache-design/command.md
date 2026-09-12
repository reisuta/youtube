# バックエンドのキャッシュ戦略 - 実演環境とコマンドのまとめ

動画「【TTL を決めて終わりにしてない？】バックエンドのキャッシュ戦略をこの動画一本で」で使った実演環境とコマンドです。
`demo/` の Dockerfile で、Node の API（:3000）、nginx の proxy_cache（:8080）、Redis が入った使い捨てコンテナができます。

## 実演環境を作る

```sh
cd demo && bash setup.sh build && bash setup.sh run     # または: docker build -t cache-demo . && docker run -it --rm --hostname demo cache-demo
```

- `app.js`: `/api/items/:id` に ETag と Cache-Control を付けて返す。DB は 1.5 秒かかる関数で代用し、`/tmp/app.log` に呼び出し回数を出す。`999` は存在しない ID。`/time` は `no-store`
- `nginx.conf`: `proxy_cache` の設定（下記）

## 第 2 章 HTTP キャッシュ

```sh
curl -si localhost:3000/api/items/1 | grep -iE "^(HTTP|ETag|Cache-Control)"
E=$(curl -si localhost:3000/api/items/1 | grep -i ^ETag | cut -d" " -f2 | tr -d "\r")
curl -si -H "If-None-Match: $E" localhost:3000/api/items/1 | head -1     # 304 Not Modified
curl -si -H 'If-None-Match: "old"' localhost:3000/api/items/1 | head -1  # 200
curl -si localhost:3000/time | grep -iE "^(HTTP|Cache-Control)"          # no-store
```

Cache-Control の要点:

| 指示 | 意味 |
|---|---|
| `max-age=N` | N 秒は再検証なしで使ってよい |
| `s-maxage=N` | CDN / プロキシだけに効く max-age |
| `public` / `private` | private はブラウザだけ。CDN に置かせない |
| `no-cache` | 置いてよいが使う前に必ず再検証 |
| `no-store` | 一切置かない |
| `must-revalidate` | 期限切れ後は古いものを使わない |
| `stale-while-revalidate=N` | 期限切れ後 N 秒は古いものを返しつつ裏で更新 |
| `stale-if-error=N` | 上流がエラーのとき N 秒は古いものを返す |
| `immutable` | 期限内は再検証しない（ハッシュ付きファイル） |

Node で ETag を返す最小例（`demo/app.js` より）:

```js
const etag = '"' + crypto.createHash("sha1").update(body).digest("hex").slice(0, 12) + '"';
const headers = { "Cache-Control": "public, max-age=10, stale-while-revalidate=30", ETag: etag };
if (req.headers["if-none-match"] === etag) { res.writeHead(304, headers); return res.end(); }
res.writeHead(200, headers); res.end(body);
```

## 第 3 章 CDN とリバースプロキシ（nginx で縮図）

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api:10m max_size=100m inactive=10m;
server {
    listen 8080;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_cache api;
        proxy_cache_key "$scheme$host$request_uri";   # キャッシュキー。Cookie を含めるかはここで決める
        proxy_cache_valid 200 404 10s;                 # 状態コードごとの TTL（404 もキャッシュ = ネガティブキャッシュ）
        proxy_cache_lock on;                           # 同じキーへの同時リクエストを 1 本に（スタンピード対策）
        proxy_cache_lock_timeout 5s;
        proxy_cache_use_stale updating error timeout;  # 更新中・上流エラー時は古いものを返す
        proxy_cache_background_update on;              # 裏で更新（stale-while-revalidate 相当）
        add_header X-Cache $upstream_cache_status always;   # MISS / HIT / STALE / UPDATING / EXPIRED
    }
}
```

```sh
curl -si localhost:8080/api/items/2 | grep -iE "^(HTTP|X-Cache)"   # MISS → HIT → (11 秒後) STALE → HIT
```

CDN 側で決めること: キャッシュキー（クエリ文字列、Cookie、Authorization を含めるか）、`Vary`（`Accept-Encoding`、`Accept-Language`）、認証付き応答は `private`、パージは伝播に時間がかかるのでハッシュ付き URL と版付きキーを優先。

## 第 4 章 アプリ側のキャッシュ

| 型 | 動き | 向く場面 |
|---|---|---|
| cache-aside | 読むとき無ければ DB → キャッシュに置く。書くときはキャッシュを**削除** | ほとんどの読み取り |
| write-through | 書くときキャッシュと DB を両方更新 | 書いた直後に読まれるデータ |
| write-behind | キャッシュに書き、DB へは後でまとめて | カウンタ、ログ。失えないものには使わない |

```sh
redis-cli SET user:1 '{"name":"alice"}' EX 10     # TTL 付きで置く
redis-cli TTL user:1                               # 残り秒数
redis-cli GET user:1                               # 期限切れ後は (nil)
redis-cli SET user:999 __NULL__ EX 30              # ネガティブキャッシュ（番人の値、短い TTL）
redis-cli CONFIG GET maxmemory-policy              # 既定 noeviction。キャッシュ用途は allkeys-lru へ
redis-cli CONFIG SET maxmemory-policy allkeys-lru   # 練習用コンテナの中で。本番の Redis に打つ前に影響を確認すること
redis-cli INFO stats | grep keyspace                # keyspace_hits / keyspace_misses でヒット率
```

cache-aside を JavaScript で書くと:

```js
async function getUser(id) {
  const key = `user:v2:${id}`;                                  // 名前空間:版:識別子
  const cached = await redis.get(key);
  if (cached === "__NULL__") return null;                       // ネガティブキャッシュ
  if (cached) return JSON.parse(cached);
  const user = await db.findUser(id);
  const ttl = 3600 + Math.floor(Math.random() * 300);           // ジッター
  await redis.set(key, user ? JSON.stringify(user) : "__NULL__", "EX", user ? ttl : 60);
  return user;
}
async function updateUser(id, patch) {
  await db.updateUser(id, patch);
  await redis.del(`user:v2:${id}`);                             // 更新ではなく削除
}
```

## 第 5 章 スタンピードと分散ロック

```sh
# スタンピード: 直接叩くと DB 5 回、nginx 越しは proxy_cache_lock で 1 回
for i in 1 2 3 4 5; do curl -s -o /dev/null -w "%{http_code} " localhost:3000/api/items/3 & done; wait; echo
grep -c item=3 /tmp/app.log
for i in 1 2 3 4 5; do curl -s -o /dev/null -w "%{http_code} " localhost:8080/api/items/4 & done; wait; echo
grep -c item=4 /tmp/app.log

# 分散ロック（最小構成）
redis-cli SET lock:report worker-A NX PX 30000      # OK（取れた）。token は自分だけの乱数にする
redis-cli SET lock:report worker-B NX PX 30000      # (nil)（取れない）
redis-cli PTTL lock:report
# 解放は「自分の token のときだけ DEL」を Lua で 1 回に
redis-cli EVAL 'if redis.call("get",KEYS[1])==ARGV[1] then return redis.call("del",KEYS[1]) else return 0 end' 1 lock:report worker-A
```

JavaScript（ioredis）での取得と解放:

```js
const token = crypto.randomUUID();
const ok = await redis.set("lock:report", token, "PX", 5000, "NX");   // "OK" か null
if (!ok) return;                                                       // 取れなければ諦めるか待つ
try { await generateReport(); }
finally {
  await redis.eval('if redis.call("get",KEYS[1])==ARGV[1] then return redis.call("del",KEYS[1]) else return 0 end', 1, "lock:report", token);
}
```

注意: Redis 単体のロックは「たまに二重に走っても壊れない処理」に使う。厳密な排他が要るなら DB のトランザクションやリース付きの合意アルゴリズム（etcd、ZooKeeper）を検討する。Redlock とその批判（Martin Kleppmann「How to do distributed locking」）も一読の価値がある。

## 第 6 章 落とし穴と計測

| 事故 | 対策 |
|---|---|
| 他人のデータが表示される | 認証付き応答は `private`。`Vary: Authorization` か Cookie |
| 更新したのに古いまま | 層を列挙して無効化の責任者を決める。版付きキー |
| DB が突然落ちる | ロック、stale、ジッター、404 の TTL |
| Redis が書けない | `maxmemory-policy` を `allkeys-lru` に。TTL を必ず付ける |
| ホットキー | アプリ内メモリに短く二重に置く。キーを分散 |
| キャッシュ汚染 | 5xx や途中の応答は置かない（404 は意図して短い TTL）。本文の検証 |

計測: CDN のログ、nginx の `X-Cache`、Redis の `INFO stats`（`keyspace_hits` / `keyspace_misses`）。キャッシュを全部消したときに DB が耐えるかを一度は試す。

**注意**: ここで扱うコマンドはすべて使い捨てコンテナの中で試す前提です。`redis-cli CONFIG SET` や `setfacl` のような設定変更を本番環境に打つ前に、影響を確認してください。
