# Progress

## Scope change (latest)
- **AI Insights (M5) and any Anthropic usage are deferred.** The `insights` function stays a 501 stub; no Anthropic key needed. Scoring uses existing algorithms only (browser speech recognition + word alignment/edit distance here; Azure Speech later for phoneme-level scores).
- **No-Xcode prototype:** `web/` is a static PWA (practice with orb, scoring, history, word bank, XP/streak, free 20-words/day cap, all in localStorage). Deployed by `.github/workflows/pages.yml` to GitHub Pages, with screenshots of each screen at `/prototypes/`. Local screenshots in `docs/prototypes/`. Scoring logic: `web/logic.js` (9 tests, run by `npm test`).
- Blocker: Pages must be enabled once: repo Settings → Pages → Source: "GitHub Actions" (the workflow tries to enable it but may lack permission). Then URL is `https://onecowonecow.github.io/pronunciation-app/`.
- Speech recognition needs Chrome/Edge/Safari (webkitSpeechRecognition) over HTTPS; other browsers use the typed-input fallback. Scores from browser recognition are approximate, not phoneme-level.

## Latest session (routine)
- Pages deploy confirmed live (HTTP 200) and CI green (backend, swift-core, ios).
- Design pass on web prototype using taste skills (redesign-existing-projects audit): focus/hover/pressed states, skip link, favicon + meta, tabular numerals, balanced text wrap, grain surface, active-tab indicator, composed empty states, clearer chip colors. Screenshots regenerated in `docs/prototypes/`.
- Next: port these refinements to SwiftUI tokens; M2 client wiring (Supabase auth/sync for the web prototype is optional, needs Supabase project).

## Latest routine run (07:48 UTC)
- Ported the scoring/alignment algorithm from `web/logic.js` to Swift (`Packages/CadenceCore/.../Alignment.swift`) with XCTests, so the native app scores identically to the web prototype. Pushed as 32ca5a2; **its CI run (swift-core + ios) has not been checked yet: next run should confirm it compiles and fix anything CI reports.**
- Design-pass Pages deploy (ac06593) succeeded.
- Next: check CI for 32ca5a2; M1 native pieces (AudioEngine level meter + SFSpeechRecognizer wrapper behind a protocol, result screen using tokens); port web design refinements to SwiftUI.

## Latest routine run (10:48 UTC)
- CI confirmed green for the Swift alignment port (swift-core + ios jobs pass).
- Added `PracticeSession` (record → score → free-tier cap state machine) + `SpeechRecognizing` protocol in CadenceCore, with fake-recognizer XCTests. **CI for this push not yet checked; verify next run.**
- Next: app-target `SFSpeechRecognizer` wrapper conforming to `SpeechRecognizing`, SwiftUI practice/result screens bound to `PracticeSession`, port web design refinements to SwiftUI tokens.

## Latest routine run (13:47 UTC)
- CI confirmed green for the PracticeSession push.
- Native M1 slice added: `SpeechRecognizer` (SFSpeechRecognizer + AVAudioEngine, on-device when supported, mic level callback), `PracticeViewModel`, `PracticeView` (category chips, hold-to-speak, orb → score ring, per-word chips with tap-to-hear via AVSpeechSynthesizer, free-cap messages), shared `Sentences` in CadenceCore, speech-recognition Info.plist string. **Not yet compiled: the iOS CI job on this push is the first check; fix anything it reports next run.**
- Needs the user (once, on a real iPhone/simulator): grant mic + speech permissions and confirm hold-to-speak feels right; the orb reacts to mic level only via `VoiceOrb(level:)`.
- Next: History + Word Bank screens (SwiftData or local JSON), tab bar with orb, port web design refinements; then M2 needs a Supabase project.

## Latest routine run (16:47 UTC)
- CI confirmed green on all pushes through 42e8232, **including the first compile of the native practice screen** (iOS build + Swift tests).
- Added `ProgressLog` (history, word bank with mastery/graduation, weekly XP, streak) in CadenceCore with 7 XCTests (week boundary is Monday; streak allows yesterday). App: `ProgressStore` (JSON persistence), History (Swift Charts), Word Bank, Week tabs, TabView root, Practice records attempts. **CI for this push not yet checked.**
- Still waiting on user: apply migration 2, deploy `save-attempt`, send the anon key (see Supabase section).
- Next: sync ProgressLog ↔ Supabase once anon key + sign-in exist; orb as center tab button; port web design refinements; review queue using `next_review_at`.

## Latest routine run (19:47 UTC)
- CI for 548bc22: iOS build passed (native tabs/progress views compile); swift-core failed one test (week boundary: Linux `dateInterval(of:.weekOfYear)` ignored `firstWeekday`). Fixed `ProgressLog.weekKey` to compute Monday from the weekday number. The fix did not change the result: the real cause was the test's expected XP (a perfect 1-word read earns 2 XP with the quality bonus; weeks were already separating correctly). Test corrected in the 22:47 run; **re-verify CI next run.** The weekKey rewrite is harmless and kept.

## Latest routine run (01:48 UTC)
- CI green on a58276c (all three jobs): Swift tests now pass; the earlier week-boundary failure was a wrong test expectation, fixed.
- M6 slice: web prototype "Your data" controls (export JSON, two-step delete all) verified in headless Chromium (download + wipe flow asserted in `tools/screenshots.mjs`, which Pages CI runs). Draft privacy policy and terms in `docs/legal-*-DRAFT.md`: **need legal review and a support email (marked TODO) before publishing; users must host them at public URLs for App Store Connect.**
- Next: native export/delete (Settings), local review reminders (UNUserNotificationCenter) for M3, orb as centre tab; sync still waiting on the anon key + migration 2 + function deploy.

## Latest routine run (04:47 UTC)
- CI green on 41d069a (all jobs) and Pages deployed (live app has the Your data controls).
- Native Settings tab: daily practice reminder (local notification via UNUserNotificationCenter, time picker), export my data (ShareLink JSON), delete all (confirmation dialog). Reminder copy + time clamping are pure logic in CadenceCore with XCTests. **CI for this push not yet checked** (iOS build compiles the new views; Linux job runs the new tests). Reminder text is fixed at scheduling time (streak/word count as of then); a later refinement can reschedule after each attempt.
- Next: orb as centre tab button; reschedule reminder after each attempt; sync once anon key + migration 2 + function deploy are done.

## Supabase session
- User reports schema applied (unverified from here: Supabase MCP not authenticated in cloud sessions).
- New migration `20260930000002_word_bank_upsert.sql` (**apply it too**): `upsert_weak_words` keeps word mastery instead of resetting it; SQL-tested.
- `save-attempt` edge function implemented (JWT-verified user → service-role writes via tested `saveAttempt` core + Supabase store). **Not deployed and not run under Deno** (no Deno/Supabase CLI here). To deploy: `supabase link --project-ref qnwhtklhucrngnobjbho && supabase functions deploy save-attempt` (or ask a local authenticated Claude session to deploy it).
- Next: web/native clients need the project URL + **anon (publishable) key** in a config file (not a secret, but I don't have it; add to `web/config.js` / `App` xcconfig) and sign-in (web: email magic link; iOS: Sign in with Apple) before sync can be wired.

## Current milestone: M0 (repo + foundations), nearly done → next M1

### Done
- Research, setup steps, plan (docs/)
- Supabase migration `supabase/migrations/20260930000001_schema.sql`: tables, signup trigger, RLS (clients read-only on scores/XP/entitlements), atomic `consume_daily_words` (20/day free cap), opt-in weekly leaderboard view
- SQL tests on real Postgres: `supabase/tests/run.sh` (RLS isolation, forged-write rejection, cap logic) ✅ passing
- Edge function stubs (speech-token, save-attempt, insights, rc-webhook, delete-account) returning 501
- Shared pure TS logic (`supabase/functions/_shared/logic.ts`: XP, week/local day, weak words, SRS, premium, RC mapping) with 7 passing tests (`npm test`)
- M1 backend core: `_shared/saveAttempt.ts` (validation, free cap, premium gate for Free Speak, word bank, server-side XP) behind a `Store` interface; 7 tests. Not yet wired into `save-attempt/index.ts` (needs Deno + Supabase client)
- Swift package `Packages/CadenceCore` (score bands, free-tier math + XCTests) — written but NOT compiled here (no Swift toolchain in sandbox)
- XcodeGen `project.yml`, app skeleton, design tokens, Voice Orb prototype — NOT compiled here
- GitHub Actions CI: backend (Linux), swift test (Linux), iOS build (macos-15) — first run not yet observed

### Next
- M1: audio engine + Azure assessment client + result screen (needs Azure key for real testing); wire `save-attempt` entrypoint to Supabase store; implement `speech-token`
- Check first CI run and fix any Swift compile errors it reports

### Blockers needing the user
- **Supabase MCP authentication (needs you):** `.mcp.json` now points at project `qnwhtklhucrngnobjbho`, but the OAuth login is interactive. In a regular terminal on your machine run `claude`, then `/mcp` → select `supabase` → Authenticate. Cloud/routine sessions can't complete it, so until then apply `supabase/migrations/*.sql` yourself (Supabase dashboard SQL editor, or `supabase db push`) and tell me when done.
- Apple Developer enrollment, Azure/Supabase/RevenueCat/Anthropic accounts + keys (see docs/02-your-setup-steps.md)
- Open the repo in Xcode 26 once (`brew install xcodegen && xcodegen generate`) to confirm the skeleton builds; Swift here is uncompiled
- Deno isn't in the sandbox, so edge-function `index.ts` entrypoints are untested; logic lives in `_shared` and is tested under Node
