# 03 · Development plan

Working name: **Cadence** (placeholder; rename freely).

## 1. Product

**Promise:** "Your accent coach that remembers you."
**Loop:** Practice (read a sentence or speak freely) → instant phoneme-level score with *why* → words you miss drop into your Word Bank → AI Insights turn your history into a weekly focus → streak + weekly league keep you coming back.

### Features (v1.0)
| Feature | What it is |
|---|---|
| **Practice** | Scripted (read this line, categories: everyday, work, interview, exam) and Free Speak (unscripted). Live waveform while recording. Result: overall, accuracy, fluency, completeness, prosody (en-US), per-word and per-phoneme heat. Tap a word to hear a model voice (Apple `AVSpeechSynthesizer`) and retry. |
| **Score History** | Timeline chart (Swift Charts) of overall + sub-scores, per-session detail, filters by week/month, personal bests, streak calendar. |
| **Word Bank** | Auto-collects words scoring < 80; manual add; each word has a mastery level, phoneme breakdown, IPA, spaced-repetition review queue. |
| **Leaderboard** | Weekly league (XP earned from practice), friends-agnostic global + country; opt-in with display name/avatar; anti-cheat via server-side XP. |
| **AI Insights** | Claude summarizes last 7/30 days: weakest phonemes, patterns (e.g. /θ/ → /s/, final consonant dropping), a 3-item weekly focus plan, encouraging tone. Premium. |
| **Account & Settings** | Sign in with Apple, profile, target accent, daily goal, reminders (local notifications), data export, **delete account**, privacy links. |
| **Premium / Paywall** | One honest paywall: monthly + annual, 7-day trial, clear terms, **Restore Purchases**, manage subscription link. |
| **Onboarding** | 60-second flow: goal → level check (3 sentences) → immediate first score → paywall *after* value is shown. |

### Free vs Premium (DECIDED)
- **Free:** capped at **20 scored words per day** (resets at local midnight), score history, word bank, leaderboard.
- **Premium ($8.99/month):** unlimited practice, Free Speak, AI Insights, all sentence packs.

### Pricing (DECIDED)
- Single plan: `premium_monthly` at **$8.99/month**. No annual plan in v1. Trial: none by default (revisit after launch).

## 2. Design direction (deliberately unlike Duolingo/ELSA/Speak)

**Concept: "Sound as light."** A dark, editorial, tactile interface where your voice literally paints the screen.

- **Palette:** near-black ink (`#0B0B10`) canvas; a single spectral gradient (violet → magenta → amber) used **only** for voice/score, so color = signal. Scores map to a luminous ring, not red/green pass/fail. Light mode: warm paper (`#F6F2EA`) with ink type.
- **Signature element: the Voice Orb**: a metaball/particle blob (SwiftUI `Canvas` + `TimelineView`, Metal shader on iOS 17+) that reacts to live mic amplitude and settles into the score ring when you finish. This is the hero of the app, the App Store screenshots, and the TikTok demos.
- **Phoneme "spectrum strips":** each word rendered as glowing phoneme chips; weak sounds are dim/dissonant, strong ones bright. Instead of red text, you *see* what's off.
- **Typography:** large serif display (e.g. *New York* system serif) for words and scores + a clean grotesque (SF Pro Rounded off; use *SF Pro* with wide tracking) for UI. Editorial, calm, confident.
- **Motion + haptics:** spring physics, haptic "tick" as the score resolves, sound design optional. Liquid Glass materials (iOS 26) for tab bar and sheets, with graceful fallback to `.ultraThinMaterial`.
- **Custom tab bar** with the Orb as the central Practice button.
- Accessibility: Dynamic Type, VoiceOver labels on scores, Reduce Motion fallback (static ring), contrast-checked palette.

## 3. Architecture

```
iOS app (SwiftUI, iOS 17+, built with Xcode 26)
 ├─ Features/ Practice, History, WordBank, Leaderboard, Insights, Settings, Paywall, Onboarding
 ├─ Core/ AudioEngine (AVAudioEngine), SpeechAssessment (Azure SDK), Auth, API client, Store (RevenueCat), Persistence (SwiftData cache)
 └─ DesignSystem/ tokens, Orb, PhonemeStrip, ScoreRing, components
        │ HTTPS (JWT from Supabase Auth)
Backend: Supabase
 ├─ Postgres (+RLS): profiles, sessions, attempts, word_bank, xp_events, leaderboard views, entitlements, insights
 ├─ Edge Functions:
 │    speech-token   → mints 10-min Azure Speech token (key never ships in app; premium/limit checks)
 │    save-attempt   → validates + stores result JSON, updates word_bank, computes XP server-side
 │    insights       → Claude (Haiku-class) summary from aggregated stats; cached weekly
 │    rc-webhook     → RevenueCat events → entitlements table
 │    delete-account → removes data, revokes Sign in with Apple token
 └─ Cron: weekly league rollover, streak freeze grants
External: Azure Speech (assessment), Anthropic API (insights), RevenueCat (IAP)
```
**Why native SwiftUI, not React Native/Flutter?** The unique UI (Orb, Metal, Liquid Glass), low-latency audio, StoreKit and the Azure iOS SDK are all first-class native; it also removes a whole class of App Review/toolchain issues.

**Privacy-by-design:** audio is streamed to Azure for assessment and **not stored by default**; only scores/phonemes are persisted. Explicit consent screen before first recording that names Azure and Anthropic as processors. Insights receive aggregated stats, never audio.

### Data model (core tables)
`profiles(id, display_name, country, target_accent, daily_goal, is_public)` · `attempts(id, user_id, mode, reference_text, overall, accuracy, fluency, completeness, prosody, result_json, created_at)` · `word_bank(user_id, word, ipa, mastery, last_score, next_review_at)` · `xp_events(user_id, amount, reason, week)` · `weekly_leaderboard` (view) · `entitlements(user_id, premium, expires_at, source)` · `insights(user_id, period, json, created_at)`

## 4. Milestones

| # | Milestone | Deliverable | Depends on you |
|---|---|---|---|
| **M0** | Repo + foundations | New private repo, docs, XcodeGen project spec, CI (GitHub Actions macOS), design tokens, backend schema/migrations | Repo created |
| **M1** | Core practice loop | Orb + recording + Azure assessment + result screen (scripted mode) | Azure key, Mac/Xcode |
| **M2** | Persistence + Auth | Sign in with Apple, Supabase schema + RLS, Score History, Word Bank | Supabase project, Apple dev acct |
| **M3** | Retention | XP/streaks, Leaderboard, reminders, onboarding | - |
| **M4** | Monetization | RevenueCat paywall, entitlements, Restore Purchases, free-tier limits, Free Speak | App Store Connect products, RevenueCat |
| **M5** | AI Insights | `insights` function, Insights screen, weekly focus | Anthropic key |
| **M6** | Compliance + polish | Account deletion, data export, consent, privacy manifest, accessibility, empty/error states, localization scaffold | Legal pages live |
| **M7** | Beta | TestFlight, crash monitoring, sandbox purchase testing, perf | Paid Apps Agreement active |
| **M8** | Launch | Screenshots, listing copy, App Privacy answers, submit, release | Everything above |

Rough calendar with parallel work on your side: ~6–8 weeks to submission, +1–2 weeks review buffer. Apple enrollment (esp. organization/D-U-N-S) is the most likely critical-path delay, so start Phase 0 today.

## 5. What I can and can't do from here
- **I can:** write the full SwiftUI app, design system, Supabase migrations and Edge Functions, tests, CI workflows, privacy policy / terms drafts, App Store listing copy, screenshot scripts.
- **I can't:** compile or run iOS code (this sandbox is Linux), create Apple/Azure/RevenueCat accounts, hold your secrets, or click Submit in App Store Connect. Backend logic (TypeScript/SQL) I can test here; Swift I'll structure as a Swift Package with pure-logic modules that *can* be unit tested on Linux, with the UI verified by you (or CI on a macOS runner) in Xcode.

## 6. App Store launch/marketing plan
- **Listing:** subtitle "Accent coach that remembers you"; keywords: pronunciation, accent, speaking, IELTS, TOEFL, interview; screenshots lead with the Orb and phoneme strips.
- **Funnel:** free "score my sentence" first-run → paywall after first score (trial-first annual).
- **Channels:** TikTok/Reels demos of the Orb reacting to real voices; Apple Search Ads on exam keywords; ASO; a small landing page.
- **Metrics to watch:** D1/D7 retention, first-score completion, trial start rate, trial→paid, refund rate.

## 7. Decisions (resolved)
Name: Cadence · English only · Individual Apple account · Free daily word cap + $8.99/mo unlimited · SwiftUI + Supabase + RevenueCat.

## 7b. Original open decisions (for reference)
1. App name / brand direction (Cadence is a placeholder)
2. Target learners: **English pronunciation only** for v1 (recommended; prosody only supports en-US) vs multi-language
3. Individual vs organization Apple account
4. Pricing ($12.99 / $59.99?) and trial length
5. Confirm native SwiftUI + Supabase + RevenueCat stack
