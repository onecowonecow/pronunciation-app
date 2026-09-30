# Cadence: agent instructions

iOS pronunciation coach. Read `docs/03-development-plan.md` first, then `PROGRESS.md`.

## Rules
- Stack: SwiftUI (iOS 17+, Xcode 26), Supabase (Postgres/RLS, Edge Functions in TypeScript/Deno), Azure Speech, Anthropic API, RevenueCat.
- Decisions are final: name Cadence, English only, free tier capped at 20 scored words/day, single $8.99/month premium plan, individual Apple account.
- Linux sandbox cannot compile Swift UI. Put pure logic in Swift Packages (`Packages/`) testable with `swift test` where possible; generate the Xcode project with XcodeGen (`project.yml`). Backend code (SQL, Edge Functions) must be tested here.
- Never commit secrets. Use `.env.example` and document required variables.
- Work milestone by milestone (M0..M8 in the plan). Small commits, push after each. Update `PROGRESS.md` (done / next / blockers needing the user) at the end of every work session.
- Do not create PRs unless asked; commit to the branch you were given.
