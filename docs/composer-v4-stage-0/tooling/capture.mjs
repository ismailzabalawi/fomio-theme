// Minimal CDP driver: node capture.mjs <shots.json> <outdir> [ids...]
import { spawn } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
const [,, shotsFile, outDir, ...only] = process.argv;
const H = process.env.HOME + "/Library/Caches/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-mac-arm64/chrome-headless-shell";
const proc = spawn(H, ["--headless", "--hide-scrollbars", "--remote-debugging-port=9333", "--force-device-scale-factor=1", "--user-data-dir=" + outDir + "/../.chrome-profile", "about:blank"], { stdio: "ignore" });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let ver; for (let i = 0; i < 50; i++) { try { ver = await (await fetch("http://127.0.0.1:9333/json/version")).json(); break; } catch { await sleep(200); } }
const targets = await (await fetch("http://127.0.0.1:9333/json/list")).json();
const ws = new WebSocket(targets.find((t) => t.type === "page").webSocketDebuggerUrl);
await new Promise((r) => ws.addEventListener("open", r));
let id = 0; const pend = new Map(); const logs = [];
ws.addEventListener("message", (e) => { const m = JSON.parse(e.data); if (m.id && pend.has(m.id)) { pend.get(m.id)(m); pend.delete(m.id); } if (m.method === "Runtime.consoleAPICalled" || m.method === "Runtime.exceptionThrown") logs.push(JSON.stringify(m.params).slice(0, 300)); });
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pend.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
await send("Page.enable"); await send("Runtime.enable");
const shots = JSON.parse(readFileSync(shotsFile, "utf8")).filter((s) => !only.length || only.includes(s[0]));
const results = [];
for (const [sid, fn, w, h, outName, props] of shots) {
  logs.length = 0;
  await send("Emulation.setDeviceMetricsOverride", { width: +w, height: +h, deviceScaleFactor: 1, mobile: false });
  await send("Page.navigate", { url: "http://127.0.0.1:8765/mockups/" + encodeURIComponent(fn) });
  let ok = false, info = null;
  for (let i = 0; i < 60; i++) {
    await sleep(500);
    const r = await send("Runtime.evaluate", { returnByValue: true, awaitPromise: true, expression: `(async()=>{await document.fonts.ready;const f=document.querySelector('[data-fmc4]');const faces=[...document.fonts].filter(x=>x.status==='loaded').map(x=>x.family.replace(/"/g,''));const fa=[...document.querySelectorAll('i[class*="fa-"]')];const faOk=fa.length===0||getComputedStyle(fa[0],'::before').content!=='none';return {frame:!!f,ready:!!(f&&f.__fmc4&&f.__fmc4.state&&f.__fmc4.state.ready),w:f?f.getBoundingClientRect().width:0,h:f?f.getBoundingClientRect().height:0,faces:[...new Set(faces)],icons:fa.length,faOk}})()` });
    info = r.result?.result?.value;
    if (info && info.frame && info.ready && info.faces.some((x) => /Source Sans/.test(x)) && info.faOk) { ok = true; break; }
  }
  await sleep(800); // let transitions settle
  const shot = await send("Page.captureScreenshot", { format: "png", clip: { x: 0, y: 0, width: +w, height: +h, scale: 1 }, captureBeyondViewport: false });
  if (shot.result?.data) writeFileSync(outDir + "/" + outName, Buffer.from(shot.result.data, "base64"));
  results.push({ sid, outName, ok, info, errors: logs.filter((l) => /error|Error|never resolved/.test(l)).slice(0, 5) });
  console.log(sid, ok ? "OK" : "INCOMPLETE", JSON.stringify(info));
}
writeFileSync(outDir + "/capture-log.json", JSON.stringify({ browser: ver?.Browser, userAgent: ver?.["User-Agent"], results }, null, 1));
ws.close(); proc.kill();
