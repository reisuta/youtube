// コネクションプールの実演。使い方: node pool.js <maxSockets|0>   0 = 制限なし
const http = require("http");
const max = Number(process.argv[2] || 0);
const agent = new http.Agent({ keepAlive: true, maxSockets: max || Infinity });
const N = 20, t0 = Date.now();
let done = 0;
for (let i = 0; i < N; i++) {
  http.get({ host: "localhost", port: 4000, path: "/work", agent }, (res) => {
    res.resume(); res.on("end", () => { if (++done === N) {
      console.log(`${N} requests, maxSockets=${max || "Infinity"}, ${Date.now() - t0}ms`);
      http.get("http://localhost:4000/peak", (r) => { let b = ""; r.on("data", (c) => b += c); r.on("end", () => { console.log("server saw peak concurrent:", JSON.parse(b).peak_concurrent); agent.destroy(); }); });
    } });
  });
}
