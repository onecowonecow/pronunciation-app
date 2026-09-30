# Progress

## Scope change (latest)
- **AI Insights (M5) and any Anthropic usage are deferred.** The `insights` function stays a 501 stub; no Anthropic key needed. Scoring uses existing algorithms only (browser speech recognition + word alignment/edit distance here; Azure Speech later for phoneme-level scores).
- **No-Xcode prototype:** `web/` is a static PWA (practice with orb, scoring, history, word bank, XP/streak, free 20-words/day cap, all in localStorage). Deployed by `.github/workflows/pages.yml` to GitHub Pages, with screenshots of each screen at `/prototypes/`. Local screenshots in `docs/prototypes/`. Scoring logic: `web/logic.js` (9 tests, run by `npm test`).
- Blocker: Pages must be enabled once: repo Settings → Pages → Source: "GitHub Actions" (the workflow tries to enable it but may lack permission). Then URL is `https://onecowonecow.github.io/pronunciation-app/`.
- Speech recognition needs Chrome/Edge/Safari (webkitSpeechRecognition) over HTTPS; other browsers use the typed-input fallback. Scores from browser recognition are approximate, not phoneme-level.

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
- Apple Developer enrollment, Azure/Supabase/RevenueCat/Anthropic accounts + keys (see docs/02-your-setup-steps.md)
- Open the repo in Xcode 26 once (`brew install xcodegen && xcodegen generate`) to confirm the skeleton builds; Swift here is uncompiled
- Deno isn't in the sandbox, so edge-function `index.ts` entrypoints are untested; logic lives in `_shared` and is tested under Node
