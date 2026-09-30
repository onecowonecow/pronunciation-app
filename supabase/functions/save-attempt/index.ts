// save-attempt: validates a scored attempt, enforces the free-tier cap and Free Speak gate,
// then writes attempt, word bank and XP with the service role. Clients cannot write these tables directly.
import { isPremium } from "../_shared/logic.ts";
import { saveAttempt, type AttemptInput } from "../_shared/saveAttempt.ts";
import { authedUserId, cors, json, serviceClient, supabaseStore } from "../_shared/supabaseStore.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const db = serviceClient();
  const userId = await authedUserId(req, db);
  if (!userId) return json({ error: "unauthorized" }, 401);

  let input: AttemptInput;
  try { input = await req.json(); } catch { return json({ error: "bad_json" }, 400); }

  const [{ data: ent }, { data: profile }] = await Promise.all([
    db.from("entitlements").select("premium, expires_at").eq("user_id", userId).maybeSingle(),
    db.from("profiles").select("timezone").eq("id", userId).maybeSingle(),
  ]);

  try {
    const result = await saveAttempt(
      supabaseStore(db), userId, isPremium(ent, new Date()), profile?.timezone ?? "UTC", input,
    );
    return result.ok ? json(result) : json({ error: result.error }, result.status);
  } catch (e) {
    console.error("save-attempt failed", e);
    return json({ error: "server_error" }, 500);
  }
});
