# Cadence Privacy Policy (DRAFT, needs legal review before publishing)

_Last updated: 2026-10-01. This draft describes how the app is designed to work. Have a lawyer review it and host it at a public URL before App Store submission._

## What Cadence does
Cadence scores how you pronounce English sentences and keeps a history so you can see progress.

## Data we process
| Data | Why | Where it goes | Kept |
|---|---|---|---|
| Voice audio while you hold the speak button | To recognise and score your speech | Processed by Apple's speech recognition (on-device where your device supports it). Azure Speech is planned for phoneme-level scoring and will be named here before it ships. | Audio is not stored by Cadence |
| Scores, per-word results, practice history, Word Bank, XP | Show your progress, build review lists | Your device; with an account, our database (Supabase) | Until you delete them |
| Account identifier (Sign in with Apple), display name and country (optional) | Sign-in, optional leaderboard | Our database (Supabase) | Until you delete your account |
| Subscription status | Unlock premium | RevenueCat and Apple | As required by those services |

We do not sell personal data and do not use it for advertising or tracking.

## Your controls
- **Export** your data from the app.
- **Delete** your data or account from the app. Deleting an account removes your records from our database.
- You can revoke microphone and speech permissions in iOS Settings at any time.

## Processors
Apple (speech recognition, sign-in, payments), Supabase (hosting and database), RevenueCat (subscriptions). Azure (speech scoring) will be added to this list if and when it is used.

## Children
Cadence is not directed at children under 13.

## Contact
TODO: support email address.

## Changes
We will update the date above when this policy changes.
