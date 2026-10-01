import { SENTENCES, scoreAttempt, bandOf, wordsRemaining, computeXp, localDay, updateMastery, FREE_DAILY_WORD_CAP, WEAK_WORD_THRESHOLD } from "./logic.js";

const $ = (id) => document.getElementById(id);
const load = (k, d) => { try { return JSON.parse(localStorage.getItem("cadence." + k)) ?? d; } catch { return d; } };
const save = (k, v) => { try { localStorage.setItem("cadence." + k, JSON.stringify(v)); } catch {} };
const state = { cat: "everyday", idx: 0, level: 0.15, target: 0.15, score: null,
  history: load("history", []), bank: load("bank", {}), usage: load("usage", {}), xp: load("xp", {}) };

// ---- tabs
document.querySelectorAll("nav button").forEach((b) => b.onclick = () => {
  document.querySelectorAll("nav button").forEach((x) => x.classList.toggle("on", x === b));
  document.querySelectorAll(".tab").forEach((t) => t.classList.toggle("active", t.id === b.dataset.tab));
  render();
});

// ---- sentences
const cats = [...new Set(SENTENCES.map((s) => s.cat))];
cats.forEach((c) => { const b = document.createElement("button"); b.textContent = c; b.dataset.cat = c; b.onclick = () => { state.cat = c; state.idx = 0; pick(); markCat(); }; $("cats").append(b); });
function markCat() { document.querySelectorAll("#cats button").forEach((x) => x.classList.toggle("on", x.dataset.cat === state.cat)); }
const list = () => SENTENCES.filter((s) => s.cat === state.cat);
function pick() { $("ref").textContent = list()[state.idx % list().length].text; $("result").hidden = true; state.score = null; $("ring").textContent = ""; }
$("next").onclick = () => { state.idx++; pick(); };

// ---- orb (canvas, amplitude-reactive; static ring under reduced motion)
const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
const cv = $("orb"), g = cv.getContext("2d");
const bandColor = { dim: "#4b4470", warming: "#7C5CFF", bright: "#FF3D9A", luminous: "#FFB020" };
function frame(t) {
  state.level += (state.target - state.level) * 0.12;
  const W = cv.width, c = W / 2, base = W * 0.2;
  g.clearRect(0, 0, W, W);
  if (state.score != null) {
    g.lineWidth = 26; g.lineCap = "round"; g.strokeStyle = "#ffffff18"; g.beginPath(); g.arc(c, c, W * 0.36, 0, 7); g.stroke();
    const gr = g.createLinearGradient(0, 0, W, W); gr.addColorStop(0, "#7C5CFF"); gr.addColorStop(.5, "#FF3D9A"); gr.addColorStop(1, "#FFB020");
    g.strokeStyle = gr; g.beginPath(); g.arc(c, c, W * 0.36, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * state.score / 100); g.stroke();
  } else {
    const gr = g.createRadialGradient(c, c, 10, c, c, W * 0.4);
    gr.addColorStop(0, "#FFB020"); gr.addColorStop(.5, "#FF3D9A"); gr.addColorStop(1, "#7C5CFF00");
    g.fillStyle = gr; g.globalAlpha = .9;
    const time = reduce ? 0 : t / 1000;
    for (let i = 0; i < 6; i++) {
      const a = time * 0.8 + i * Math.PI / 3, r = base * (0.4 + 1.1 * state.level);
      g.beginPath(); g.arc(c + Math.cos(a) * r, c + Math.sin(a * 1.3) * r, base * (1 + state.level * .4), 0, 7); g.fill();
    }
    g.globalAlpha = 1;
  }
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);

// ---- microphone level + speech recognition (both optional)
const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
let stream, actx, analyser, levelTimer, rec, started = 0, heard = "", conf = null;
async function startMeter() {
  try {
    stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    actx = new AudioContext(); analyser = actx.createAnalyser(); analyser.fftSize = 512;
    actx.createMediaStreamSource(stream).connect(analyser);
    const buf = new Uint8Array(analyser.fftSize);
    levelTimer = setInterval(() => { analyser.getByteTimeDomainData(buf);
      let s = 0; for (const v of buf) s += ((v - 128) / 128) ** 2; state.target = Math.min(1, Math.sqrt(s / buf.length) * 5); }, 50);
  } catch { levelTimer = setInterval(() => state.target = 0.3 + Math.random() * 0.5, 120); }
}
function stopMeter() { clearInterval(levelTimer); state.target = 0.15; stream?.getTracks().forEach((t) => t.stop()); actx?.close(); }

async function begin() {
  if (!SR) { $("status").textContent = "Speech recognition isn't available in this browser. Use the typed box below."; $("typed").open = true; return; }
  $("rec").classList.add("live"); $("rec").textContent = "Listening…"; $("status").textContent = "";
  state.score = null; $("result").hidden = true; heard = ""; conf = null; started = Date.now();
  rec = new SR(); rec.lang = "en-US"; rec.interimResults = false; rec.maxAlternatives = 1; rec.continuous = true;
  rec.onresult = (e) => { for (const r of e.results) { heard += " " + r[0].transcript; conf = r[0].confidence; } };
  rec.onerror = (e) => { $("status").textContent = "Mic error: " + e.error; };
  rec.onend = () => finish();
  rec.start(); startMeter();
}
function end() { if (rec) { rec.stop(); } stopMeter(); $("rec").classList.remove("live"); $("rec").textContent = "Hold to speak"; }
const recBtn = $("rec");
recBtn.onpointerdown = begin; recBtn.onpointerup = end; recBtn.onpointerleave = () => rec && end();
function finish() { const secs = (Date.now() - started) / 1000; if (heard.trim()) submit(heard, { confidence: conf, seconds: secs }); else $("status").textContent = "Didn't catch that. Try again."; rec = null; }
$("typedform").onsubmit = (e) => { e.preventDefault(); const v = $("typedinput").value; if (v.trim()) submit(v, {}); };

// ---- scoring + free-tier cap
function submit(text, opts) {
  const ref = $("ref").textContent, day = localDay();
  const used = state.usage[day] ?? 0, left = wordsRemaining(used);
  if (left === 0) { $("status").textContent = `Daily free limit reached (${FREE_DAILY_WORD_CAP} words). Premium unlocks unlimited practice.`; return; }
  const r = scoreAttempt(ref, text, opts);
  const scored = r.words.slice(0, left);
  state.usage[day] = used + scored.length;
  state.score = r.overall; showResult(r, scored.length < r.words.length);
  const xp = computeXp(scored.length, r.overall);
  const wk = weekKey(); state.xp[wk] = (state.xp[wk] ?? 0) + xp;
  state.history.push({ t: Date.now(), ref, overall: r.overall, accuracy: r.accuracy, completeness: r.completeness, fluency: r.fluency });
  for (const w of scored) {
    const cur = state.bank[w.word];
    if (w.accuracy < WEAK_WORD_THRESHOLD) state.bank[w.word] = { mastery: cur ? updateMastery(cur.mastery, w.accuracy) : 0, last: w.accuracy };
    else if (cur) { cur.mastery = updateMastery(cur.mastery, w.accuracy); cur.last = w.accuracy; if (cur.mastery >= 5) delete state.bank[w.word]; }
  }
  save("history", state.history); save("bank", state.bank); save("usage", state.usage); save("xp", state.xp); renderCap();
}
function weekKey() { const d = new Date(); d.setDate(d.getDate() - ((d.getDay() + 6) % 7)); return localDay(d); }

function showResult(r, limited) {
  $("result").hidden = false; $("ring").textContent = r.overall;
  $("scores").innerHTML = [["Overall", r.overall], ["Accuracy", r.accuracy], ["Complete", r.completeness], ["Fluency", r.fluency ?? "–"]]
    .map(([k, v]) => `<div><b>${v}</b><small>${k}</small></div>`).join("");
  $("words").innerHTML = "";
  r.words.forEach((w) => { const b = document.createElement("div"); b.className = "chip " + bandOf(w.accuracy);
    b.innerHTML = `${w.word}<small>${w.heard ? (w.accuracy < 100 ? "heard “" + w.heard + "”" : "✓") : "missed"}</small>`;
    b.onclick = () => speechSynthesis?.speak(Object.assign(new SpeechSynthesisUtterance(w.word), { lang: "en-US", rate: .8 })); $("words").append(b); });
  $("status").textContent = limited ? "Some words weren't scored: daily free limit reached." : "";
}

// ---- other tabs
function renderCap() { $("cap").textContent = `${wordsRemaining(state.usage[localDay()] ?? 0)} free words left today`; }
function render() {
  renderCap();
  $("hlist").innerHTML = state.history.slice(-20).reverse().map((h) => `<li><span>${h.ref.slice(0, 34)}…</span><b>${h.overall}</b></li>`).join("") || "<li class=muted>No attempts yet. Read a sentence aloud and your scores will chart here.</li>";
  const ch = $("chart").getContext("2d"), W = 600, H = 200; ch.clearRect(0, 0, W, H);
  const pts = state.history.slice(-30); ch.strokeStyle = "#FF3D9A"; ch.lineWidth = 3; ch.beginPath();
  pts.forEach((p, i) => { const x = pts.length < 2 ? W / 2 : 20 + i * (W - 40) / (pts.length - 1), y = H - 10 - (H - 20) * p.overall / 100; i ? ch.lineTo(x, y) : ch.moveTo(x, y); }); ch.stroke();
  const words = Object.entries(state.bank).sort((a, b) => a[1].last - b[1].last);
  $("blist").innerHTML = words.map(([w, v]) => `<li><span>${w}</span><span>score ${Math.round(v.last)} · level ${v.mastery}/5</span></li>`).join("") || "<li class=muted>Nothing to review. Words you score under 80 collect here for practice.</li>";
  $("xp").textContent = (state.xp[weekKey()] ?? 0) + " XP";
  const days = new Set(state.history.map((h) => localDay(new Date(h.t)))); let s = 0, d = new Date();
  if (!days.has(localDay(d))) d.setDate(d.getDate() - 1);
  while (days.has(localDay(d))) { s++; d.setDate(d.getDate() - 1); } $("streak").textContent = s;
}
// ---- onboarding: goal, then straight into a first sentence
const GOALS = [["everyday", "Everyday conversation"], ["work", "Work and meetings"], ["interview", "Job interviews"], ["exam", "An English exam"]];
function finishOnboarding(goal) {
  try { localStorage.setItem("cadence.onboarded", "1"); } catch {}
  if (goal) { state.cat = goal; state.idx = 0; pick(); markCat(); }
  $("onboard").hidden = true;
  if (goal) $("status").textContent = "Hold the button and read the sentence aloud. That's your first score.";
}
function startOnboarding() {
  let seen = false; try { seen = localStorage.getItem("cadence.onboarded") === "1"; } catch {}
  if (seen || state.history.length) return;
  $("ob-goals").innerHTML = "";
  GOALS.forEach(([id, label]) => { const b = document.createElement("button"); b.textContent = label; b.onclick = () => finishOnboarding(id); $("ob-goals").append(b); });
  $("ob-skip").onclick = () => finishOnboarding(null);
  $("onboard").hidden = false; $("ob-goals").firstChild.focus();
}

// ---- data controls (export / delete)
const DATA_KEYS = ["history", "bank", "usage", "xp"];
$("export").onclick = () => {
  const out = Object.fromEntries(DATA_KEYS.map((k) => [k, state[k]]));
  const url = URL.createObjectURL(new Blob([JSON.stringify({ exportedAt: new Date().toISOString(), ...out }, null, 2)], { type: "application/json" }));
  Object.assign(document.createElement("a"), { href: url, download: "cadence-data.json" }).click();
  URL.revokeObjectURL(url); $("datamsg").textContent = "Exported cadence-data.json.";
};
let wipeArmed = null;
$("wipe").onclick = () => {
  const b = $("wipe");
  if (!wipeArmed) {
    b.textContent = "Tap again to confirm"; $("datamsg").textContent = "This removes your history, Word Bank, XP and daily usage from this browser.";
    wipeArmed = setTimeout(() => { wipeArmed = null; b.textContent = "Delete all my data"; $("datamsg").textContent = ""; }, 5000); return;
  }
  clearTimeout(wipeArmed); wipeArmed = null;
  try { DATA_KEYS.forEach((k) => localStorage.removeItem("cadence." + k)); } catch {}
  state.history = []; state.bank = {}; state.usage = {}; state.xp = {};
  b.textContent = "Delete all my data"; $("datamsg").textContent = "All data deleted."; render();
};

pick(); markCat(); render(); startOnboarding();
window.__cadence = { submit, state }; // for tests/screenshots
