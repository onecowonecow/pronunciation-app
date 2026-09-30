import { test } from "node:test";
import assert from "node:assert/strict";
import { saveAttempt, type Store, type AttemptInput } from "./saveAttempt.ts";

function fake(used = 0) {
  const log = { attempts: [] as any[], bank: [] as any[], xp: [] as any[], used };
  const store: Store = {
    async consumeDailyWords(_u, _d, req, cap) { const a = Math.max(0, Math.min(req, cap - log.used)); log.used += a; return a; },
    async insertAttempt(r) { log.attempts.push(r); return "att-1"; },
    async upsertWordBank(r) { log.bank.push(...r); },
    async insertXp(r) { log.xp.push(r); },
  };
  return { store, log };
}
const words = (n: number, acc = 90) => Array.from({ length: n }, (_, i) => ({ word: `w${String.fromCharCode(97 + i)}`, accuracy: acc }));
const input = (o: Partial<AttemptInput> = {}): AttemptInput => ({ mode: "scripted", overall: 85, words: words(10), result_json: {}, ...o });
const now = new Date("2026-09-30T12:00:00Z");

test("free user within cap scores all words and earns XP", async () => {
  const { store, log } = fake();
  const r = await saveAttempt(store, "u", false, "UTC", input(), now);
  assert.deepEqual(r, { ok: true, attemptId: "att-1", scoredWords: 10, xp: 13, limited: false });
  assert.equal(log.xp[0].week, "2026-09-28");
});
test("free user is truncated at the 20/day cap", async () => {
  const { store } = fake(15);
  const r = await saveAttempt(store, "u", false, "UTC", input(), now);
  assert.equal(r.ok && r.scoredWords, 5);
  assert.equal(r.ok && r.limited, true);
});
test("free user at cap gets 402", async () => {
  const { store } = fake(20);
  const r = await saveAttempt(store, "u", false, "UTC", input(), now);
  assert.deepEqual(r, { ok: false, status: 402, error: "daily_cap_reached" });
});
test("premium bypasses cap", async () => {
  const { store } = fake(20);
  const r = await saveAttempt(store, "u", true, "UTC", input({ words: words(25) }), now);
  assert.equal(r.ok && r.scoredWords, 25);
});
test("free speak requires premium", async () => {
  const { store } = fake();
  const r = await saveAttempt(store, "u", false, "UTC", input({ mode: "free" }), now);
  assert.equal(!r.ok && r.status, 402);
});
test("weak words land in word bank", async () => {
  const { store, log } = fake();
  await saveAttempt(store, "u", true, "UTC", input({ words: [{ word: "Think", accuracy: 40 }, { word: "the", accuracy: 95 }] }), now);
  assert.deepEqual(log.bank.map((b) => b.word), ["think"]);
});
test("rejects out-of-range scores", async () => {
  const { store } = fake();
  const r = await saveAttempt(store, "u", true, "UTC", input({ overall: 140 }), now);
  assert.deepEqual(r, { ok: false, status: 400, error: "bad_overall" });
});
