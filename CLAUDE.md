# PaceShift — developer guide

Adaptive marathon training app (Flutter, Android-first). The race date is a fixed anchor; when runs are
missed, a pure scheduling engine redistributes the load within safety guardrails instead of shifting
everything later. Local-first — Health Connect and notifications are enhancements, not hard dependencies.

See `paceshift_build_spec.md` for the full product spec.

## Toolchain

- Flutter is pinned via **FVM** (`.fvmrc` → 3.41.8). **Always run Flutter through `fvm`**, e.g.
  `fvm flutter analyze`, `fvm flutter test`, `fvm flutter run`.
- Codegen (Drift, freezed, json): `fvm dart run build_runner build` (the `--delete-conflicting-outputs`
  flag is now the ignored default). Generated `*.g.dart` / `*.freezed.dart` are committed and excluded
  from analysis (see `analysis_options.yaml`).
- Android: `applicationId` is `com.paceshift.app`; the activity package/namespace is
  `com.paceshift.paceshift` (so launch intent is `com.paceshift.app/com.paceshift.paceshift.MainActivity`).
  `minSdk 26`, core-library desugaring on, `MainActivity : FlutterFragmentActivity` (Health Connect needs it).

## Architecture (feature-first, clean layering)

```
lib/
  core/          theme, date utils, formatting, enums
  data/
    db/          Drift tables, AppDatabase + DAOs, row↔model mappers
    health/      HealthService (Health Connect on Android / HealthKit on iOS)
    repositories/plan, run, settings, scheduler, sync
  domain/        PURE — no Flutter/IO imports
    models/      freezed entities + enums
    plan_generator/  PlanGenerator
    engine/      AdaptiveScheduler (the heart) + ScheduleSnapshot + RescheduleOutcome
    readiness/   ReadinessScorer
  presentation/  today/ plan/ run_detail/ stats/ onboarding/ sync/ settings/ + providers + widgets + router
  services/      notifications/ (flutter_local_notifications), background/ (workmanager)
test/            engine/ (§4.8 suite), plan_generator/, readiness/
```

**Engine contract (keep this invariant):** `domain/engine` and `domain/plan_generator` are **pure Dart**.
The engine reads an in-memory `ScheduleSnapshot` and returns a `RescheduleOutcome` (a diff + changelog +
optional degrade decisions). It never touches Drift. `SchedulerRepository` builds the snapshot, runs the
engine, and persists the diff in a transaction. This is what keeps the engine exhaustively unit-testable —
do not add Flutter/DB imports to it.

State management is **Riverpod 3.x** with hand-written providers (no codegen — `riverpod_generator`/`_lint`
were dropped due to a `freezed 3.x` version conflict). Note Riverpod 3 uses `asyncValue.value` (not
`valueOrNull`).

## Automatic run capture

Runs are meant to arrive on their own; manual entry is the fallback, not the default path. Four
non-obvious rules keep this working:

1. **Sync before rollover — always.** `runDayRollover()` marks past pending runs `missed` and
   redistributes their load, and a missed run is a weak match candidate. Syncing first means a run the
   athlete actually did is attached before the engine judges it. Both `main.dart` and the background
   worker are ordered this way. If a sync *does* recover a `missed` run it sets
   `SyncResult.recoveredMissedRun`, and `syncAndSettle()` (`presentation/providers/providers.dart`)
   re-runs the rollover so the engine can reconcile.
2. **Permission state is tri-state, not a bool.** `HealthService.permissionStatus()` returns
   `bool?` — Apple deliberately never discloses READ grants, so iOS always answers `null`. Collapsing
   null to false makes iOS look permanently denied and re-prompts on every sync. `SyncRepository`
   resolves it against the persisted `settings.healthPromptedAt`.
3. **Automatic syncs never prompt.** `SyncTrigger.automatic` (launch, resume, background) suppresses
   permission requests — a system dialog appearing unbidden on resume reads as a bug. Only
   `SyncTrigger.manual` may raise one.
4. **Matching is pure.** `domain/sync/workout_matcher.dart` follows the same contract as `domain/engine`
   — no Flutter/IO/Drift. It matches within ±1 day and a 60–200% distance band; anything ambiguous
   returns a *suggestion* that lands in `completed_runs.suggestedPlannedRunId` and is confirmed by the
   user on Today, so a short jog can't silently mark a long run done. Tests: `test/sync/`.

Read types are platform-filtered through `Health.isDataTypeAvailable` — distance is `DISTANCE_DELTA` on
Health Connect but `DISTANCE_WALKING_RUNNING` on HealthKit, and requesting an unsupported type fails the
whole authorization call.

**iOS background task — three strings must agree**, or the app *crashes on launch*: the Dart `uniqueName`
(`BackgroundTasks.uniquePeriodic`), the `Info.plist` `BGTaskSchedulerPermittedIdentifiers` entry, and the
`WorkmanagerPlugin.registerPeriodicTask(withIdentifier:)` call in `AppDelegate.swift` — all
`paceshift.periodic`. iOS requires the handler to be registered *before launch finishes*, so it must live
in `didFinishLaunchingWithOptions`; Dart's `registerPeriodicTask` only submits the request. Without the
AppDelegate registration, `BGTaskScheduler.submit` raises an uncaught **NSException** ("No launch handler
registered…") that no Dart `try/catch` can absorb.

## Common commands

- Run tests: `fvm flutter test` (engine suite is the primary correctness gate).
- Analyze: `fvm flutter analyze` (should be clean).
- Run on emulator: `fvm flutter run -d emulator-5554`.
- Regenerate after changing tables/models/enums: `fvm dart run build_runner build`.

## Commercialization layer (Phases 6–11)

Built on top of the spec. See `LAUNCH.md` for the full handoff (credentials, deploy, store checklist).

- **Engine depth** (`lib/domain/paces/`, `lib/domain/fitness/`): VDOT/Riegel `PaceCalculator`,
  `FitnessEstimator`, `RacePredictor`; `WorkoutSegment` structured workouts on `PlannedRun`; optional
  `goalFinishSec` in `PlanInput`. All pure + unit-tested (`test/paces`, `test/fitness`).
- **Backend** (`backend/`): Kotlin **Ktor 3** + Exposed + Postgres + Flyway + JWT. Email/pw + Google/Apple
  OAuth, plan **sync** (opaque JSON state, last-writer-wins), RevenueCat `/billing/webhook`, and a Claude
  **AI proxy** (`/ai/explain`, `/ai/chat`). The engine stays **client-side** — the server never runs it.
  Run: `cd backend && docker compose up -d db && ./gradlew run`. Tests: `./gradlew test` (Testcontainers, or
  set `TEST_DATABASE_URL`). Build/test via host `./gradlew` (Java 17) or the `gradle:8.12-jdk17` Docker image;
  Docker Desktop must be running for Testcontainers/compose.
- **Client API layer** (`lib/data/api/`): Dio `ApiClient` (JWT refresh interceptor, base URL via
  `--dart-define=API_BASE_URL`, default `10.0.2.2:8080`), `AuthRepository`, `CloudSyncRepository`,
  `AiRepository`; tokens in `flutter_secure_storage`. Riverpod: `lib/presentation/providers/auth_providers.dart`.
- **Monetization**: RevenueCat (`purchases_flutter`) behind a `SubscriptionService` interface
  (`UnconfiguredSubscriptionService` default; real impl needs `--dart-define=REVENUECAT_API_KEY`). Gate Pro
  features with `ensurePro(context, ref)` (`lib/presentation/widgets/pro_gate.dart`); paywall in
  `lib/presentation/paywall/`. Pro = adaptive engine + AI + full stats + **cloud** sync. Plan generation
  **and automatic run capture are free** — capture is the core loop, and gating it would leave free users
  hand-typing runs. Do not add `ensurePro` to any health-sync path.
- **iOS**: `ios/` target with HealthKit (`Runner.entitlements` + Info.plist usage strings), background modes,
  **deployment target 14.0** (Podfile + pbxproj + post_install — required by `workmanager_apple`). Builds &
  runs in the iOS Simulator; TestFlight/device needs an Apple Developer account (see `LAUNCH.md`).
  Notifications are cross-platform (`DarwinInitializationSettings` + iOS permission request).
- **AI**: server holds `ANTHROPIC_API_KEY`; default model `claude-opus-4-8`. Responses are **grounded** in the
  engine's `RescheduleOutcome` changelog (`changeLines()` in `lib/presentation/shift/shift_summary.dart`).

## Generative UI (Phase 12)

AI coaching can render **native, AI-composed UI** instead of plain text, using Flutter's official **`genui`**
SDK (A2UI protocol). Flow: a separate backend route `POST /ai/ui` (`GenUiService.kt`) proxies **GLM 5.2**
(Zhipu/Z.ai, OpenAI-compatible — `GLM_API_KEY`/`GLM_BASE_URL`/`GLM_MODEL`, independent of the Claude path),
which returns a **stable flat UI spec** (`{"blocks":[…]}`, allow-listed + parsed/filtered server-side — see
`GenUiTest`). The client (`lib/data/api/genui_repository.dart`) fetches it and `specToMessages()`
(`lib/presentation/genui/paceshift_catalog.dart`) maps it to genui A2UI messages rendered by a PaceShift
widget catalog. `GenUiSurfaceView` owns the genui `SurfaceController`/`Conversation` and handles interactions
(`GenUiAction`) client-side. Surfaces wired: Coach chat (`coach_chat_sheet.dart`), Shift "Coach's take" +
a lazy Pro-gated **Coach's briefing** card on the dashboard (`today_screen.dart`), and the `/coach` screen
(`ask_coach_screen.dart`). Generated `action_button`s execute **real engine actions** and then re-compose
(the feedback loop): `open_run` deep-links, `mark_done` → `RunRepository.updateRunStatus`, `could_not_run`
→ `SchedulerRepository.reportCouldNotRun` (handles `needsDecision` via `DegradeDecisionSheet`). **The engine
stays pure + client-side** — GLM only *arranges grounded facts*; the client performs the action. genui's
`Catalog` validation + safe fallbacks mean malformed model output degrades rather than crashes.

## Status

Spec Phases 1–5 + commercialization Phases 6–11 implemented and verified (`fvm flutter analyze` clean,
full `fvm flutter test` green, Android emulator + iOS Simulator golden paths walked, backend auth/sync
verified). Live paths for billing/AI/social-login/TestFlight are credential-gated — see `LAUNCH.md`.
**Firebase cloud backup from the original spec is superseded** by the Kotlin/Ktor backend's sync.
