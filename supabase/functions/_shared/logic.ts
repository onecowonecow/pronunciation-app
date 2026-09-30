// Pure logic shared by edge functions. No Deno/Node APIs so it runs under both.
export const FREE_DAILY_WORD_CAP = 20;
export const WEAK_WORD_THRESHOLD = 80;

/** Monday (UTC) of the week containing `d`, as YYYY-MM-DD. */
export function weekStart(d: Date): string {
  const x = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
  const dow = (x.getUTCDay() + 6) % 7; // Mon=0
  x.setUTCDate(x.getUTCDate() - dow);
  return x.toISOString().slice(0, 10);
}

/** Local calendar day (YYYY-MM-DD) for an IANA timezone. */
export function localDay(d: Date, timeZone: string): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone, year: "numeric", month: "2-digit", day: "2-digit" }).format(d);
}

/** XP is computed server-side: 1 per scored word, bonus for quality. */
export function computeXp(wordCount: number, overall: number): number {
  if (wordCount <= 0) return 0;
  const bonus = overall >= 90 ? Math.ceil(wordCount * 0.5) : overall >= 80 ? Math.ceil(wordCount * 0.25) : 0;
  return wordCount + bonus;
}

export interface WordResult { word: string; accuracy: number; ipa?: string }

export function weakWords(words: WordResult[]): WordResult[] {
  const seen = new Map<string, WordResult>();
  for (const w of words) {
    const key = w.word.toLowerCase().replace(/[^a-z'-]/g, "");
    if (!key || w.accuracy >= WEAK_WORD_THRESHOLD) continue;
    const prev = seen.get(key);
    if (!prev || w.accuracy < prev.accuracy) seen.set(key, { ...w, word: key });
  }
  return [...seen.values()];
}

/** Next spaced-repetition review time from mastery level (0..5). */
export function nextReview(now: Date, mastery: number): Date {
  const days = [0, 1, 3, 7, 14, 30][Math.max(0, Math.min(5, mastery))];
  return new Date(now.getTime() + days * 86_400_000);
}

export function isPremium(e: { premium: boolean; expires_at: string | null } | null, now: Date): boolean {
  if (!e?.premium) return false;
  return e.expires_at === null || new Date(e.expires_at) > now;
}

/** Maps RevenueCat webhook event type to premium state. */
export function rcEventToPremium(type: string): boolean | null {
  switch (type) {
    case "INITIAL_PURCHASE": case "RENEWAL": case "UNCANCELLATION": case "PRODUCT_CHANGE": case "NON_RENEWING_PURCHASE":
      return true;
    case "EXPIRATION": case "REFUND":
      return false;
    default: return null; // CANCELLATION keeps access until expiry; ignore
  }
}
