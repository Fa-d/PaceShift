# PaceShift — Launch & Commercialization Handoff

Phases 6–11 took PaceShift from a working Android app to a commercial, cross-platform
product: deeper adaptive engine, a Kotlin/Ktor backend with accounts + cloud sync,
RevenueCat freemium monetization, iOS/HealthKit parity, and Claude-powered AI coaching.

This document lists what's built, what needs **your credentials** to go live, and the
store-submission checklist.

## What's built & verified

| Area | Status |
|---|---|
| Engine depth (VDOT paces, goal-time, fitness, race prediction, structured workouts) | ✅ pure Dart, unit-tested, wired into onboarding/run-detail/stats |
| Backend (Ktor + Postgres + Flyway + JWT, auth + sync + billing webhook + AI proxy) | ✅ compiles, Testcontainers + live curl verified |
| Accounts + cloud sync (email/pw + Google + Apple; push/pull opaque state) | ✅ end-to-end on device against the live server |
| Monetization (RevenueCat freemium, paywall, `requirePro` gating) | ✅ gating + paywall verified; **sandbox/real products need your keys** |
| iOS + HealthKit (target, entitlements, Info.plist, notifications, BGTask) | ✅ builds + runs in the iOS Simulator; **device/TestFlight needs your Apple account** |
| AI coaching (Claude via Ktor proxy, grounded explanations + chat) | ✅ compiles + wired; **needs `ANTHROPIC_API_KEY` on the server** |
| Generative UI (GLM 5.2 via Ktor proxy → genui-rendered native surfaces) | ✅ backend compiles + unit-tested; **needs `GLM_API_KEY` on the server** |
| Launch hygiene (account deletion, medical disclaimer) | ✅ in app + backend |

## Credentials you must supply

1. **Anthropic API key** — set `ANTHROPIC_API_KEY` on the backend (never in the app).
   The AI endpoints return 503 until it's set. Model defaults to `claude-opus-4-8`
   (override with `ANTHROPIC_MODEL`).
1b. **GLM 5.2 key (generative UI)** — set `GLM_API_KEY` on the backend (never in the
   app). Powers `POST /ai/ui`, which returns a structured UI spec the app renders
   natively (genui). Returns 503 until set. Base URL defaults to Z.ai
   (`https://api.z.ai/api/paas/v4`) and model to `glm-5.2`; override with `GLM_BASE_URL`
   / `GLM_MODEL` to use another OpenAI-compatible provider (Together `zai-org/GLM-5.2`,
   AIMLAPI `zhipu/glm-5-2`, OpenRouter…). Independent of the Claude key — the two AI
   paths can be configured separately.
   - **Verify a key** without launching the app:
     `GLM_API_KEY=… backend/scripts/glm_smoke_test.sh` (add `glm-4.5-flash` as an arg to
     test the **free tier** that needs no balance). It checks auth and that the model
     returns a valid `/ai/ui` spec.
   - **`glm-5.2`/`glm-4.6` need a funded Z.ai account** (otherwise `1113 Insufficient
     balance`). To run with no balance, set `GLM_MODEL=glm-4.5-flash`.
   - **Point the app at your local backend** with the VS Code run configs in
     `.vscode/launch.json` (physical device → Mac LAN IP, Android emulator →
     `10.0.2.2:8080`, iOS sim → `localhost:8080`), or
     `fvm flutter run --dart-define=API_BASE_URL=http://<host>:8080`.
   - **Physical device on the same Wi-Fi:** the app's default `API_BASE_URL` is the
     dev machine's LAN IP (`http://192.168.0.213:8080` — update in
     `lib/data/api/api_client.dart` if your router reassigns it). The backend already
     binds `0.0.0.0`. Cleartext HTTP is permitted in **debug builds only** (Android:
     `android/app/src/debug/res/xml/network_security_config.xml`; iOS:
     `NSAllowsLocalNetworking` + `NSLocalNetworkUsageDescription` in `Info.plist`). If
     it can't connect: allow the incoming connection in the macOS firewall, make sure
     Wi-Fi "AP/client isolation" is off, and on iOS tap **Allow** on the local-network
     prompt. Verify from another device: `curl http://192.168.0.213:8080/health`.
2. **RevenueCat** — create a project + a `pro` entitlement + products; run the app with
   `--dart-define=REVENUECAT_API_KEY=<public sdk key>`. Point RevenueCat's webhook at
   `POST /billing/webhook` with `REVENUECAT_AUTH_TOKEN` set on the backend.
3. **Google sign-in** — create OAuth client IDs (Android/iOS/web); set `GOOGLE_CLIENT_IDS`
   on the backend (audience check) and run the app with
   `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>`. Add the iOS URL scheme +
   Android SHA-1.
4. **Apple sign-in** — enable the capability in the Apple Developer portal; set the
   Service ID in `APPLE_CLIENT_IDS` on the backend (defaults to `com.paceshift.app`).
5. **Apple Developer account** — Team ID + signing for TestFlight/device builds and the
   HealthKit capability on hardware.

## Backend: run & deploy

Local (already verified):
```bash
cd backend
docker compose up -d db                 # Postgres on :5432
./gradlew run                           # Ktor on :8080  (or: docker compose up api)
./gradlew test                          # auth + sync suites (set TEST_DATABASE_URL or use Testcontainers)
```
The Flutter app points at `http://10.0.2.2:8080` on the Android emulator by default;
override with `--dart-define=API_BASE_URL=https://api.yourdomain.com`.

**Deploy** (documented, not done): build the image (`backend/Dockerfile`), push to a host
(Railway/Fly/Render/GCP), provision managed Postgres, set the env vars above + a strong
`JWT_SECRET`, and run behind TLS. Flyway migrates on boot.

## iOS: finish for the App Store

1. Open `ios/Runner.xcworkspace` in Xcode, select the Runner target → Signing & Capabilities.
2. Set your Team; add the **HealthKit** capability (the `Runner.entitlements` file is
   already present — set `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` if Xcode
   hasn't linked it).
3. Add the **Background Modes** capability (Background fetch + Background processing — keys
   are already in Info.plist).
4. Register `com.paceshift.app.periodicSync` for BGTaskScheduler (already in Info.plist).
5. Create the App Store Connect record, archive, and upload to TestFlight.
6. Validate HealthKit + a real watch run on device.

## Health Connect (Android) — Play Store

Personal sideloading needs no review, but **publishing on Google Play requires the
Health Connect data-use declaration + review**. Declare each READ type used
(ExerciseSession, Distance, HeartRate, Calories, Steps) and link a privacy policy.

## Store submission checklist

- [ ] Privacy policy URL (covers Health data, account data, AI processing) — required by both stores.
- [ ] Health Connect Play data-use declaration submitted.
- [ ] HealthKit App Review notes (why each read type is used).
- [ ] Account deletion is in-app (Settings → Account → Delete account → `DELETE /profile`) ✅.
- [ ] Medical/injury disclaimer shown ✅ (Settings footer).
- [ ] Apple Sign-In offered alongside Google (App Store rule) ✅.
- [ ] Store listings + screenshots + ASO.
- [ ] Analytics + crash reporting (recommend Sentry app+backend, PostHog events) — not yet wired.

## Free vs Pro (current gating)

- **Free:** generate & track a plan, manual logging, Today/Plan/Stats basics.
- **Pro:** the adaptive "Couldn't run today" engine, Health Connect/HealthKit sync,
  cloud backup, and AI coaching. Plan generation is intentionally free so the Day-0
  "aha" lands before the paywall.
