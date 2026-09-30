// Pure, dependency-free logic for the web prototype (mirrors CadenceCore + backend rules).
export const FREE_DAILY_WORD_CAP = 20;
export const WEAK_WORD_THRESHOLD = 80;

export const normalize = (s) =>
  s.toLowerCase().replace(/[^a-z0-9'\s-]/g, " ").split(/\s+/).filter(Boolean);

export function levenshtein(a, b) {
  const m = a.length, n = b.length;
  let prev = Array.from({ length: n + 1 }, (_, j) => j);
  for (let i = 1; i <= m; i++) {
    const cur = [i];
    for (let j = 1; j <= n; j++)
      cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    prev = cur;
  }
  return prev[n];
}

/** 0..100 similarity of two words by edit distance. */
export function wordSimilarity(a, b) {
  if (a === b) return 100;
  if (!a.length && !b.length) return 100;
  // A different word was recognised, so it counts as weak (< WEAK_WORD_THRESHOLD) however close it is.
  return Math.min(WEAK_WORD_THRESHOLD - 1, Math.round((1 - levenshtein(a, b) / Math.max(a.length, b.length)) * 100));
}

/** Align reference words to heard words (DP, cost = 1 - similarity). Returns per-reference-word results. */
export function alignWords(reference, heard) {
  const R = normalize(reference), H = normalize(heard);
  const GAP = 1;
  const cost = (i, j) => 1 - wordSimilarity(R[i], H[j]) / 100;
  const d = Array.from({ length: R.length + 1 }, () => new Array(H.length + 1).fill(0));
  for (let i = 1; i <= R.length; i++) d[i][0] = i * GAP;
  for (let j = 1; j <= H.length; j++) d[0][j] = j * GAP;
  for (let i = 1; i <= R.length; i++)
    for (let j = 1; j <= H.length; j++)
      d[i][j] = Math.min(d[i - 1][j - 1] + cost(i - 1, j - 1), d[i - 1][j] + GAP, d[i][j - 1] + GAP);
  const out = [];
  let i = R.length, j = H.length;
  while (i > 0) {
    if (j > 0 && Math.abs(d[i][j] - (d[i - 1][j - 1] + cost(i - 1, j - 1))) < 1e-9) {
      out.unshift({ word: R[i - 1], heard: H[j - 1], accuracy: wordSimilarity(R[i - 1], H[j - 1]) }); i--; j--;
    } else if (Math.abs(d[i][j] - (d[i - 1][j] + GAP)) < 1e-9) {
      out.unshift({ word: R[i - 1], heard: null, accuracy: 0 }); i--;
    } else { j--; }
  }
  return out;
}

const clamp = (x) => Math.max(0, Math.min(100, x));

/** Score an attempt. `confidence` (0..1, optional) comes from the recognizer; `seconds` is speaking time. */
export function scoreAttempt(reference, heard, { confidence = null, seconds = null } = {}) {
  const words = alignWords(reference, heard);
  if (!words.length) return { overall: 0, accuracy: 0, completeness: 0, fluency: null, words };
  const accuracy = words.reduce((s, w) => s + w.accuracy, 0) / words.length;
  const completeness = (words.filter((w) => w.heard).length / words.length) * 100;
  let fluency = null;
  if (seconds && seconds > 0) {
    const wpm = (words.length / seconds) * 60;
    fluency = clamp(wpm < 90 ? 100 - (90 - wpm) * 1.2 : wpm > 180 ? 100 - (wpm - 180) * 1.2 : 100);
  }
  const conf = confidence == null ? null : clamp(confidence * 100);
  let overall = accuracy * 0.6 + completeness * 0.2 + (fluency ?? accuracy) * 0.1 + (conf ?? accuracy) * 0.1;
  return {
    overall: Math.round(clamp(overall)), accuracy: Math.round(accuracy), completeness: Math.round(completeness),
    fluency: fluency == null ? null : Math.round(fluency), words,
  };
}

export const bandOf = (s) => (s < 50 ? "dim" : s < 75 ? "warming" : s < 90 ? "bright" : "luminous");

export function localDay(d = new Date()) {
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}

export const wordsRemaining = (used) => Math.max(0, FREE_DAILY_WORD_CAP - Math.max(0, used));

export function computeXp(wordCount, overall) {
  if (wordCount <= 0) return 0;
  return wordCount + (overall >= 90 ? Math.ceil(wordCount * 0.5) : overall >= 80 ? Math.ceil(wordCount * 0.25) : 0);
}

export const SRS_DAYS = [0, 1, 3, 7, 14, 30];
export function updateMastery(mastery, accuracy) {
  return accuracy >= WEAK_WORD_THRESHOLD ? Math.min(5, mastery + 1) : Math.max(0, mastery - 1);
}

export const SENTENCES = [
  { cat: "everyday", text: "I think the weather is lovely this morning." },
  { cat: "everyday", text: "Could you please repeat that more slowly?" },
  { cat: "work", text: "Let's schedule a meeting to review the quarterly results." },
  { cat: "work", text: "I would like to thank everyone for their thoughtful feedback." },
  { cat: "interview", text: "My greatest strength is solving difficult problems under pressure." },
  { cat: "exam", text: "Thirty thousand thoughts thrilled the three thin thinkers." },
];
