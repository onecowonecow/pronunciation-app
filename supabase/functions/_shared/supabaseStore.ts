import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import type { Store } from "./saveAttempt.ts";

export const cors = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
};

export const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "content-type": "application/json" } });

/** Service-role client: bypasses RLS. Only ever used after the caller's JWT is verified. */
export function serviceClient(): SupabaseClient {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false },
  });
}

/** Verifies the bearer token and returns the user id, or null. */
export async function authedUserId(req: Request, db: SupabaseClient): Promise<string | null> {
  const token = req.headers.get("authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return null;
  const { data, error } = await db.auth.getUser(token);
  return error || !data.user ? null : data.user.id;
}

const must = <T>(r: { data: T | null; error: { message: string } | null }): T => {
  if (r.error || r.data === null) throw new Error(r.error?.message ?? "no data");
  return r.data;
};

export function supabaseStore(db: SupabaseClient): Store {
  return {
    async consumeDailyWords(userId, day, requested, cap) {
      return must(await db.rpc("consume_daily_words", { p_user: userId, p_day: day, p_requested: requested, p_cap: cap })) as number;
    },
    async insertAttempt(row) {
      return must(await db.from("attempts").insert(row).select("id").single()).id as string;
    },
    async upsertWordBank(rows) {
      const userId = rows[0].user_id as string;
      const words = rows.map((r) => ({ word: r.word, ipa: r.ipa, accuracy: r.last_score }));
      const { error } = await db.rpc("upsert_weak_words", { p_user: userId, p_words: words });
      if (error) throw new Error(error.message);
    },
    async insertXp(row) {
      const { error } = await db.from("xp_events").insert(row);
      if (error) throw new Error(error.message);
    },
  };
}
