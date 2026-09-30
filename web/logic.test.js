import { test } from "node:test";
import assert from "node:assert/strict";
import { normalize, levenshtein, alignWords, scoreAttempt, bandOf, wordsRemaining, computeXp, updateMastery } from "./logic.js";

test("normalize", () => assert.deepEqual(normalize("Hello, World!"), ["hello", "world"]));
test("levenshtein", () => { assert.equal(levenshtein("kitten", "sitting"), 3); assert.equal(levenshtein("", "abc"), 3); });
test("perfect read scores 100", () => {
  const r = scoreAttempt("I think so", "i think so");
  assert.equal(r.overall, 100); assert.equal(r.completeness, 100);
});
test("th->s substitution lowers that word only", () => {
  const r = scoreAttempt("I think so", "I sink so");
  assert.ok(r.words[1].accuracy < 80); assert.equal(r.words[1].heard, "sink"); assert.equal(r.words[0].accuracy, 100);
});
test("missing word is flagged", () => {
  const r = scoreAttempt("the quick brown fox", "the brown fox");
  assert.equal(r.words.find((w) => w.word === "quick").heard, null);
  assert.equal(r.completeness, 75);
});
test("extra heard words don't crash and are ignored", () => {
  const r = scoreAttempt("hello", "uh hello there");
  assert.equal(r.words.length, 1); assert.equal(r.words[0].accuracy, 100);
});
test("empty heard scores 0", () => assert.equal(scoreAttempt("hello world", "").overall, 0));
test("fluency penalises very slow speech", () => {
  assert.equal(scoreAttempt("a b c d e f", "a b c d e f", { seconds: 3 }).fluency, 100);
  assert.ok(scoreAttempt("a b c d e f", "a b c d e f", { seconds: 20 }).fluency < 60);
});
test("bands, cap, xp, mastery", () => {
  assert.equal(bandOf(95), "luminous"); assert.equal(bandOf(10), "dim");
  assert.equal(wordsRemaining(15), 5); assert.equal(wordsRemaining(30), 0);
  assert.equal(computeXp(10, 95), 15);
  assert.equal(updateMastery(5, 90), 5); assert.equal(updateMastery(0, 10), 0); assert.equal(updateMastery(2, 50), 1);
});
