import { test } from "node:test";
import assert from "node:assert/strict";
import { weekStart, localDay, computeXp, weakWords, nextReview, isPremium, rcEventToPremium } from "./logic.ts";

test("weekStart returns Monday", () => {
  assert.equal(weekStart(new Date("2026-09-30T12:00:00Z")), "2026-09-28");
  assert.equal(weekStart(new Date("2026-09-28T00:00:00Z")), "2026-09-28");
  assert.equal(weekStart(new Date("2026-10-04T23:59:00Z")), "2026-09-28");
});
test("localDay respects timezone", () => {
  const d = new Date("2026-09-30T03:00:00Z");
  assert.equal(localDay(d, "UTC"), "2026-09-30");
  assert.equal(localDay(d, "America/Los_Angeles"), "2026-09-29");
});
test("computeXp", () => {
  assert.equal(computeXp(0, 100), 0);
  assert.equal(computeXp(10, 70), 10);
  assert.equal(computeXp(10, 85), 13);
  assert.equal(computeXp(10, 95), 15);
});
test("weakWords dedupes, normalizes, keeps lowest", () => {
  const r = weakWords([{ word: "Think,", accuracy: 60 }, { word: "think", accuracy: 40 }, { word: "the", accuracy: 95 }, { word: "!!", accuracy: 10 }]);
  assert.deepEqual(r.map((w) => [w.word, w.accuracy]), [["think", 40]]);
});
test("nextReview grows with mastery", () => {
  const n = new Date("2026-09-30T00:00:00Z");
  assert.equal(nextReview(n, 0).getTime(), n.getTime());
  assert.equal(nextReview(n, 3).toISOString(), "2026-10-07T00:00:00.000Z");
  assert.equal(nextReview(n, 99).toISOString(), "2026-10-30T00:00:00.000Z");
});
test("isPremium honours expiry", () => {
  const n = new Date("2026-09-30T00:00:00Z");
  assert.equal(isPremium(null, n), false);
  assert.equal(isPremium({ premium: true, expires_at: null }, n), true);
  assert.equal(isPremium({ premium: true, expires_at: "2026-09-29T00:00:00Z" }, n), false);
  assert.equal(isPremium({ premium: true, expires_at: "2026-10-29T00:00:00Z" }, n), true);
});
test("rcEventToPremium", () => {
  assert.equal(rcEventToPremium("RENEWAL"), true);
  assert.equal(rcEventToPremium("EXPIRATION"), false);
  assert.equal(rcEventToPremium("CANCELLATION"), null);
});
