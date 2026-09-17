// 動画用の「不安定な外部 API」。:4000 で待ち受ける。
//   GET  /ok       すぐ 200
//   GET  /work     200ms 待ってから 200（コネクションプールの実演）
//   GET  /slow     5 秒待ってから 200（タイムアウトの実演）
//   GET  /flaky    3 回に 2 回は 503（リトライの実演）
//   POST /pay      決済の真似。Idempotency-Key があれば同じ結果を返す（冪等性の実演）
//   GET  /charges  作られた決済の一覧
//   同時接続数を数えて、ピークをログに出す（コネクションプールの実演）
const http = require("http");
let flakyCount = 0, inflight = 0, peak = 0, seq = 0;
const charges = [], idem = new Map();
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
http.createServer(async (req, res) => {
  inflight++; peak = Math.max(peak, inflight);
  const done = (code, body, extra = {}) => { inflight--; res.writeHead(code, { "Content-Type": "application/json", ...extra }); res.end(JSON.stringify(body) + "\n"); };
  if (req.url === "/ok") return done(200, { ok: true });
  if (req.url === "/work") { await sleep(200); return done(200, { ok: true }); }   // 200ms かかる処理
  if (req.url === "/slow") { await sleep(5000); return done(200, { ok: true, slow: true }); }
  if (req.url === "/flaky") { flakyCount++; if (flakyCount % 3 !== 0) return done(503, { error: "unavailable" }, { "Retry-After": "1" }); return done(200, { ok: true, attempt: flakyCount }); }
  if (req.url === "/peak") { const p = peak; peak = inflight; return done(200, { peak_concurrent: p }); }
  if (req.url === "/charges") return done(200, { count: charges.length, charges });
  if (req.url === "/pay" && req.method === "POST") {
    let body = ""; for await (const c of req) body += c;
    const key = req.headers["idempotency-key"];
    if (key && idem.has(key)) return done(200, { ...idem.get(key), replayed: true });
    await sleep(300);                                   // 決済処理の真似
    const charge = { id: `ch_${++seq}`, amount: JSON.parse(body || "{}").amount ?? 0 };
    charges.push(charge);
    if (key) idem.set(key, charge);
    return done(201, charge);
  }
  done(404, { error: "not found" });
}).listen(4000, () => console.log("upstream on :4000"));
