// Serves web/ and captures screenshots + a smoke test with Playwright. Usage: node tools/screenshots.mjs <outdir>
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join } from "node:path";
import { chromium } from "playwright";
const out = process.argv[2] ?? "screenshots";
const types = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".webmanifest": "application/json" };
const srv = createServer(async (q, s) => {
  try { const p = q.url === "/" ? "/index.html" : q.url.split("?")[0]; const b = await readFile(join("web", p)); s.writeHead(200, { "content-type": types[extname(p)] ?? "text/plain" }); s.end(b); }
  catch { s.writeHead(404); s.end(); }
}).listen(0);
const url = `http://localhost:${srv.address().port}/`;
const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
const errors = []; page.on("pageerror", (e) => errors.push(e.message));
await page.goto(url);
await page.screenshot({ path: `${out}/1-practice.png` });
await page.evaluate(() => window.__cadence.submit("I sink the weather is lovely this morning", {}));
await page.waitForTimeout(400);
await page.screenshot({ path: `${out}/2-result.png` });
for (const [tab, n] of [["history", 3], ["bank", 4], ["league", 5]]) { await page.click(`nav [data-tab=${tab}]`); await page.screenshot({ path: `${out}/${n}-${tab}.png` }); }
await page.click("nav [data-tab=league]");
const [dl] = await Promise.all([page.waitForEvent("download"), page.click("#export")]);
const exported = JSON.parse(await (await import("node:fs/promises")).readFile(await dl.path(), "utf8"));
if (dl.suggestedFilename() !== "cadence-data.json" || !exported.history?.length || !exported.bank?.think) { console.error("export failed", exported); process.exit(1); }
await page.click("#wipe"); const armed = await page.textContent("#wipe");
await page.click("#wipe");
const left = await page.textContent("#cap");
const msg = await page.textContent("#datamsg");
if (armed !== "Tap again to confirm" || msg !== "All data deleted." || !left.startsWith("20 ")) { console.error("wipe flow failed", { armed, msg, left }); process.exit(1); }
const cap = await page.textContent("#cap");
await browser.close(); srv.close();
if (errors.length) { console.error("page errors:", errors); process.exit(1); }
console.log("ok; cap label:", cap);
