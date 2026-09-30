-- Upsert weak words without resetting progress: existing words keep their mastery (minus one, floor 0)
-- and get a fresh review time; new words start at mastery 0. Service role only.
create function public.upsert_weak_words(p_user uuid, p_words jsonb)
returns void language sql security definer set search_path = public as $$
  insert into word_bank (user_id, word, ipa, mastery, last_score, next_review_at)
  select p_user, lower(w->>'word'), w->>'ipa', 0, (w->>'accuracy')::numeric, now()
  from jsonb_array_elements(p_words) w
  on conflict (user_id, word) do update
    set last_score = excluded.last_score,
        ipa = coalesce(excluded.ipa, word_bank.ipa),
        mastery = greatest(word_bank.mastery - 1, 0),
        next_review_at = now();
$$;
revoke all on function public.upsert_weak_words from public, anon, authenticated;
