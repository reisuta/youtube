// fd 上限の実演。使い方: node fdtest.js <接続数>   事前に ulimit -n を小さくしておく
const net = require("net");
const N = Number(process.argv[2] || 50);
let opened = 0, failed = 0, firstErr = null;
const socks = [];
const finish = () => { if (finish.done) return; finish.done = true;
  console.log(`opened ${opened} sockets, failed ${failed}` + (firstErr ? ` (first error at #${firstErr.i}: ${firstErr.code})` : ""));
  socks.forEach((s) => s.destroy()); };
for (let i = 0; i < N; i++) {
  const s = net.connect(4000, "localhost");
  s.on("connect", () => { if (++opened + failed === N) finish(); });
  s.on("error", (e) => { failed++; firstErr ||= { i: i + 1, code: e.code }; if (opened + failed === N) finish(); });
  socks.push(s);
}
setTimeout(finish, 1500);
