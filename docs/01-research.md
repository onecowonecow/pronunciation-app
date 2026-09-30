# 01 · Market research: pronunciation apps (as of Sept 2026)

## The landscape

| App | Positioning | Pronunciation depth | Monetization | Notes |
|---|---|---|---|---|
| **ELSA Speak** | "Practice conversations with AI"; pro/career + exam prep (IELTS/TOEFL/TOEIC) | Phoneme-level scoring, word stress, intonation; American/British/Australian accents | Freemium; monthly ≈ $19.99, 3-mo ≈ $40–52, annual ≈ $71–130 (several price tests visible) | 4.8★ / ~113K ratings, 25M+ users (54M downloads claimed early 2025). ~200K downloads and ~$400K revenue/month (US iOS estimate) |
| **Speak** (Speakeasy Labs) | Conversation-first fluency tutor; OpenAI-backed | Feedback embedded in AI conversation; less phoneme granularity | Subscription | $162M raised, ~$1B+ valuation, 15M+ downloads, 4.8★. Gamification tied to *speaking output*: streaks, freezes, leaderboards, challenges |
| **Hello Nabu, Speechling, Promova, Rosetta Stone, Pimsleur** | Mixed: free AI phoneme feedback, human coaching, listen-and-repeat | Varies | Mixed | Speechling differentiates with human coaches |
| **Duolingo** | Not pronunciation-first, but the gamification benchmark | Shallow | Ads + Super | Streaks, XP, leagues drive habit (reported ~60% commitment lift from streaks, ~40% engagement lift from leaderboards) |

## What they got right (copy the mechanics, not the look)
1. **Phoneme-level feedback is the table stakes.** Reviews say to look for sound / stress / rhythm level feedback, not one opaque score. The "why" ("stress the 2nd syllable") is what gets recommended.
2. **Free, instant "speech analyzer" as top of funnel.** ELSA's free analyzer converts professionals to paid at lower CAC.
3. **Habit loop = streak + XP + weekly league.** Speak shows you can do it "just enough" without childishness.
4. **Multiple price points; annual is the hero.** ELSA has run many paywall variants (2021 to 2023). Trial exists. Monthly is priced high as an anchor so annual looks cheap.
5. **Marketing:** short-form video (TikTok/Reels) showing the AI's live feedback on a real voice; localized creators; Apple Search Ads (ELSA reported +26% iOS downloads in a quarter and +30% subscribers YoY); high-intent search (IELTS/TOEFL); email/push segmented by native language and level.
6. **App Store listing:** benefit-led subtitle ("Practice Conversations with AI"), screenshots showing real feedback screens, career/exam use cases.

## What users complain about (our openings)
- Voice detection unreliable / harsh scoring with no explanation
- Subscription price inconsistency and confusing paywalls (**trust gap**)
- Bugs
- Generic feedback that doesn't remember *your* recurring mistakes

## Positioning we can own
> **"Your accent coach that actually remembers you."** Personal weak-sound map, transparent scoring (show *why*), honest simple pricing, and a look nobody else has.

Differentiators to build the app around:
- **Weak-sound map** persisted across sessions (word bank and AI insights feed off it)
- **One honest paywall**: one free tier with real value, two plans (monthly / annual), 7-day trial, clear terms, no dark patterns
- **Distinct visual identity** (see plan): dark, editorial, "sound as light", not green cartoon mascots and not a sterile chat UI

## Technology findings
- **Azure Speech Pronunciation Assessment** is the pragmatic engine: accuracy, fluency, completeness, prosody (prosody **en-US only**), scores at phoneme/syllable(en-US)/word/full-text level; 0–100 scale (`HundredMark`); scripted (read this sentence) and unscripted (free speech) modes; SDK ≥ 1.35 for prosody. Billed as standard real-time STT ≈ **$1.32 per audio hour** (prorated per second; ~$0.0037 per 10-second attempt). Not available in the cheaper fast-transcription endpoint.
- **Purchases:** RevenueCat is free up to $2,500 monthly tracked revenue then 1%; uses StoreKit 2 under the hood; handles receipt validation, entitlements, webhooks. StoreKit 2 direct is viable but you own validation + App Store Server Notifications V2.
- **Apple fees:** Small Business Program = 15% commission from day one if < $1M proceeds (otherwise 30% year one, 15% after year one per subscriber).

## Apple rules that shape the design
- **Digital subscriptions must use In-App Purchase (Guideline 3.1.1).** "Apple Pay" is for physical goods/services; it cannot be the payment method for the premium subscription. The user still pays with Apple Pay-backed cards via the standard StoreKit sheet, which is what "Apple Pay in-app" effectively means for subscriptions.
- **Restore Purchases button is mandatory** (3.1.2).
- **In-app account deletion is mandatory** if accounts exist (5.1.1(v)); with Sign in with Apple you must revoke tokens via the REST API.
- **Sign in with Apple** must be offered if any third-party login is offered.
- **Disclose sharing of voice/personal data with third-party AI** and get consent (5.1.2(i)); microphone purpose string; Privacy Nutrition Labels; privacy manifest.
- **Build requirement:** since April 28, 2026, uploads require **Xcode 26+ / iOS 26 SDK**.

## Sources
- Talkio: https://www.talkio.ai/blog/best-ai-language-speaking-practice-apps-in-2026
- Hello Nabu: https://www.hellonabu.com/blog/en/best-app-for-pronunciation-practice/
- Lingrow: https://lingrow.io/blog/best-language-apps-with-real-time-pronunciation-feedback
- ELSA App Store listing: https://apps.apple.com/us/app/elsa-speak-english-learning/id1083804886
- ELSA paywalls (Adapty): https://adapty.io/paywall-library/elsa/
- ELSA marketing: https://businessmodelcanvastemplate.com/blogs/marketing-strategy/elsa-marketing-strategy · https://ads.apple.com/app-store/success-stories/elsa
- Speak funding: https://techcrunch.com/2022/11/17/speak-lands-investment-from-openai-to-expand-its-language-learning-platform/
- Speak review: https://makeheadway.com/blog/speak-app-review/
- Duolingo gamification: https://www.925studios.co/blog/duolingo-design-breakdown
- Azure Pronunciation Assessment: https://learn.microsoft.com/en-us/azure/ai-services/speech-service/how-to-pronunciation-assessment
- Azure pricing Q&A: https://learn.microsoft.com/en-us/answers/questions/5608069/pricing-and-usage-of-pronunciation-assessment-feat
- RevenueCat vs StoreKit 2: https://theswiftk.it.com/blog/storekit-2-vs-revenuecat-ios-subscriptions
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- SDK requirements: https://developer.apple.com/news/upcoming-requirements/
- Small Business Program: https://developer.apple.com/app-store/small-business-program/
- Developer Program enrollment: https://developer.apple.com/programs/enroll/

> Caveat: download/revenue figures come from third-party estimates and marketing blogs; treat them as directional.
