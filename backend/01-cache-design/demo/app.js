// 動画用の最小 API。"DB" は 1.5 秒かかる関数で代用し、呼ばれた回数をログに出す。
const http = require("http");
const crypto = require("crypto");
let dbCalls = 0;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function db(id) {
  dbCalls++;
  console.log(`[db] query #${dbCalls} item=${id}`);
  await sleep(1500);
  if (id === "999") return null;                       // 存在しない
  return { id, name: `item-${id}`, price: 100 * Number(id) };
}
http.createServer(async (req, res) => {
  const url = new URL(req.url, "http://localhost");
  if (url.pathname === "/time") {                      // 毎回変わる。キャッシュ禁止
    res.writeHead(200, { "Content-Type": "text/plain", "Cache-Control": "no-store" });
    return res.end(new Date().toISOString() + "\n");
  }
  const m = url.pathname.match(/^\/api\/items\/(\d+)$/);
  if (!m) { res.writeHead(404); return res.end("not found\n"); }
  const item = await db(m[1]);
  if (!item) { res.writeHead(404, { "Cache-Control": "public, max-age=30" }); return res.end('{"error":"not found"}\n'); }
  const body = JSON.stringify(item) + "\n";
  const etag = '"' + crypto.createHash("sha1").update(body).digest("hex").slice(0, 12) + '"';
  const headers = { "Content-Type": "application/json", "Cache-Control": "public, max-age=10, stale-while-revalidate=30", ETag: etag };
  if (req.headers["if-none-match"] === etag) { res.writeHead(304, headers); return res.end(); }
  res.writeHead(200, headers);
  res.end(body);
}).listen(3000, () => console.log("app on :3000"));
