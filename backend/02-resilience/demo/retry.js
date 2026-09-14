// 指数バックオフ＋ジッター付きのリトライ。使い方: node retry.js /flaky
const path = process.argv[2] || "/flaky";
const RETRY_STATUS = new Set([502, 503, 504, 429]);
async function withRetry(fn, { retries = 4, base = 200, max = 2000 } = {}) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await fn(attempt);
    } catch (e) {
      if (attempt > retries || !e.retryable) throw e;
      const backoff = Math.min(max, base * 2 ** (attempt - 1));
      const wait = Math.round(backoff / 2 + Math.random() * backoff / 2);   // ジッター（半分〜全量）
      console.log(`  attempt ${attempt} failed (${e.message}) → wait ${wait}ms`);
      await new Promise((r) => setTimeout(r, wait));
    }
  }
}
withRetry(async (attempt) => {
  const res = await fetch("http://localhost:4000" + path, { signal: AbortSignal.timeout(2000) });
  if (RETRY_STATUS.has(res.status)) { const e = new Error(`HTTP ${res.status}`); e.retryable = true; throw e; }
  if (!res.ok) throw new Error(`HTTP ${res.status} (no retry)`);
  console.log(`  attempt ${attempt} OK:`, await res.text().then((t) => t.trim()));
}).catch((e) => { console.log("  gave up:", e.message); process.exit(1); });
