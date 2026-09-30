import { computeXp, FREE_DAILY_WORD_CAP, localDay, weakWords, weekStart, nextReview, type WordResult } from "./logic.ts";

export interface AttemptInput {
  mode: "scripted" | "free";
  reference_text?: string;
  overall: number; accuracy?: number; fluency?: number; completeness?: number; prosody?: number;
  words: WordResult[];
  result_json: unknown;
}

/** Storage seam so the core is testable without Supabase. */
export interface Store {
  consumeDailyWords(userId: string, day: string, requested: number, cap: number): Promise<number>;
  insertAttempt(row: Record<string, unknown>): Promise<string>;
  upsertWordBank(rows: Record<string, unknown>[]): Promise<void>;
  insertXp(row: Record<string, unknown>): Promise<void>;
}

export type SaveResult =
  | { ok: true; attemptId: string; scoredWords: number; xp: number; limited: boolean }
  | { ok: false; status: number; error: string };

const inRange = (n: unknown) => typeof n === "number" && n >= 0 && n <= 100;

export function validate(i: AttemptInput): string | null {
  if (i.mode !== "scripted" && i.mode !== "free") return "bad_mode";
  if (!inRange(i.overall)) return "bad_overall";
  for (const k of ["accuracy", "fluency", "completeness", "prosody"] as const) {
    if (i[k] !== undefined && !inRange(i[k])) return `bad_${k}`;
  }
  if (!Array.isArray(i.words) || i.words.length > 200) return "bad_words";
  if (i.words.some((w) => typeof w.word !== "string" || !inRange(w.accuracy))) return "bad_words";
  return null;
}

export async function saveAttempt(
  store: Store, userId: string, premium: boolean, timeZone: string, input: AttemptInput, now = new Date(),
): Promise<SaveResult> {
  const err = validate(input);
  if (err) return { ok: false, status: 400, error: err };
  if (input.mode === "free" && !premium) return { ok: false, status: 402, error: "premium_required" };

  const requested = input.words.length;
  const allowed = premium ? requested
    : await store.consumeDailyWords(userId, localDay(now, timeZone), requested, FREE_DAILY_WORD_CAP);
  if (!premium && requested > 0 && allowed === 0) return { ok: false, status: 402, error: "daily_cap_reached" };

  const scored = input.words.slice(0, allowed);
  const attemptId = await store.insertAttempt({
    user_id: userId, mode: input.mode, reference_text: input.reference_text ?? null, word_count: allowed,
    overall: input.overall, accuracy: input.accuracy ?? null, fluency: input.fluency ?? null,
    completeness: input.completeness ?? null, prosody: input.prosody ?? null, result_json: input.result_json,
  });
  const weak = weakWords(scored);
  if (weak.length) {
    await store.upsertWordBank(weak.map((w) => ({
      user_id: userId, word: w.word, ipa: w.ipa ?? null, mastery: 0, last_score: w.accuracy,
      next_review_at: nextReview(now, 0).toISOString(),
    })));
  }
  const xp = computeXp(allowed, input.overall);
  if (xp > 0) await store.insertXp({ user_id: userId, amount: xp, reason: "practice", week: weekStart(now) });
  return { ok: true, attemptId, scoredWords: allowed, xp, limited: allowed < requested };
}
