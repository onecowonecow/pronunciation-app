# 02 · What you need to do on your end

Things only you can do (accounts, legal identity, money, keys). Order matters; the long-lead items are first.

## Phase 0: Start now (long lead times)
- [ ] **Get a Mac with Xcode 26+.** iOS apps can't be compiled or archived on Linux. (No Mac? Use GitHub Actions macOS runners or Xcode Cloud, but you still want a Mac or a Mac cloud rental such as MacinCloud for first-time signing and TestFlight debugging.)
- [ ] **Decide individual vs organization.**
  - Individual: Apple ID + card, approval ~1–3 days, App Store shows your personal name.
  - Organization: needs a legal entity and a free **D-U-N-S number** (request from Dun & Bradstreet, can take 1–2+ weeks); approval 7+ days; shows company name.
- [ ] **Enroll in the Apple Developer Program** ($99/yr): https://developer.apple.com/programs/enroll/ (turn on two-factor auth on the Apple ID).
- [ ] **Create the GitHub repo** (see the repo note in chat): private, name `pronunciation-app`, empty.
- [ ] **Pick the app name + bundle ID** (e.g. `com.yourname.appname`). Check the App Store name is available and do a quick trademark search.
- [ ] **Buy a domain** (needed for privacy policy, support URL, marketing page, universal links).

## Phase 1: Apple side (after enrollment is approved)
- [ ] App Store Connect → **Agreements, Tax, and Banking** → accept the **Paid Apps Agreement**, add bank account and tax forms (W-9 / W-8BEN). *In-app purchases will not work in production until this is Active.*
- [ ] Apply for the **App Store Small Business Program** (15% commission): https://developer.apple.com/app-store/small-business-program/
- [ ] Certificates, Identifiers & Profiles → register the **App ID** with capabilities: **Sign in with Apple**, **In-App Purchase**, **Push Notifications**.
- [ ] Create the **app record** in App Store Connect (name, bundle ID, SKU, primary language, category = Education).
- [ ] Create **subscriptions** (App Store Connect → Monetization → Subscriptions): one subscription group "Premium" with a single product
  - `premium_monthly`
  - Price: $8.99/month.
- [ ] Generate keys:
  - **In-App Purchase key** (App Store Connect → Users and Access → Integrations) → `.p8` + Key ID + Issuer ID
  - **Sign in with Apple key** (Certificates, Identifiers & Profiles → Keys) → `.p8` + Key ID + Team ID
  - (Optional) **APNs key** for push reminders
- [ ] Create **Sandbox testers** (App Store Connect → Users and Access → Sandbox) for purchase testing.

## Phase 2: Payments (RevenueCat, recommended)
- [ ] Create a free RevenueCat account: https://www.revenuecat.com (free until $2,500/mo revenue, then 1%).
- [ ] Add the iOS app; upload the IAP `.p8` key + Issuer ID; note the **public SDK key**.
- [ ] Create entitlement `premium`, an Offering `default` with the monthly product.
- [ ] Set the **webhook** to our backend (I'll give you the URL and shared secret once the backend is deployed).

## Phase 3: Backend + AI accounts
- [ ] **Supabase** account (Postgres, Auth, Edge Functions, Storage): create a project, note Project URL, anon key, service-role key (**never commit these**).
- [ ] **Azure account** → create a **Speech** resource (region close to your users, e.g. `eastus`): note Key + Region. Add a budget alert (e.g. $25/mo).
- [ ] **Anthropic API key** (console.anthropic.com) for AI Insights; set a monthly spend limit.
- [ ] Sign in with Apple: in Supabase Auth enable the Apple provider using your Services ID / key.
- [ ] Hosting for the static site: Cloudflare Pages / Vercel (free) for the privacy policy, terms, support page.

## Phase 4: Legal + store assets
- [ ] **Privacy Policy** and **Terms of Use (EULA)** at public URLs (I'll draft; have counsel review, since you record voice and send it to AI vendors).
- [ ] **Support URL** and contact email.
- [ ] **App Privacy questionnaire** in App Store Connect (I'll give exact answers: audio data, identifiers, purchases, usage data, linked to user, used for app functionality).
- [ ] Decide **age rating** (likely 4+/9+) and **export compliance** (uses standard HTTPS only, so exempt).
- [ ] **Screenshots** (6.9" and 6.5" iPhone are the sizes I'll generate from the app) + app preview video.
- [ ] Prepare a **demo account** for App Review (or make sign-in optional for the free tier).

## Phase 5: Launch
- [ ] Install builds via **TestFlight** (internal, then 5–10 external testers).
- [ ] Submit for review (typical first review 24–48h; expect one rejection round).
- [ ] Set up **App Store Connect analytics + RevenueCat charts**, respond to reviews.
- [ ] Marketing: TikTok/Reels account, Apple Search Ads (start ~$20/day), landing page.

## Secrets I will need (send via your secret manager or env vars, never in chat or git)
`AZURE_SPEECH_KEY`, `AZURE_SPEECH_REGION`, `ANTHROPIC_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `REVENUECAT_PUBLIC_SDK_KEY`, `REVENUECAT_WEBHOOK_SECRET`, Apple `.p8` keys + IDs (Team ID, Key IDs, Issuer ID).

## Rough costs
| Item | Cost |
|---|---|
| Apple Developer Program | $99/yr |
| Domain | ~$12/yr |
| Supabase | Free → $25/mo when you outgrow it |
| Azure Speech | ~$1.32 / audio hour (≈ $0.004 per 10s attempt) |
| Claude API (insights) | pennies per user per week with Haiku-class model |
| RevenueCat | Free < $2.5K MTR, then 1% |
| Apple commission | 15% (Small Business Program) |
