# PaceShift — Adaptive Marathon Training App
## Complete Build Specification & Claude Code Prompt

> **How to use this document:** Hand this entire file to Claude Code as the project brief. It is written so Claude Code can build the app in ordered phases (see *Build Phases*). Build phase by phase, write tests for the Adaptive Engine before wiring the UI to it, and confirm each phase compiles and runs before moving on. Working name is **PaceShift** — rename freely.

---

## 1. What we're building

A personal Android app that:

1. Holds a structured marathon training plan with a **fixed race date** (the anchor).
2. Pulls completed run data automatically from a **Samsung / Wear OS watch** via **Health Connect**.
3. When the user misses a run, an **adaptive scheduling engine** intelligently redistributes the missed work across the remaining days — protecting the race date and the athlete's safety, rather than blindly shifting everything later.
4. Reminds the user of today's run and nudges them in the evening if it wasn't done.
5. Shows progress: weekly volume, long-run progression, and a "race readiness" score.

This is a single-user, local-first app (no login required). Cloud backup is an optional later phase.

---

## 2. Recommended stack (and why)

| Concern | Choice | Why |
|---|---|---|
| Framework | **Flutter (Dart)** | Single codebase, fast iteration, mature Health Connect access via the `health` package. Android-first because the watch is Samsung; iOS is a future option. |
| State management | **Riverpod** | Compile-safe, testable, great for the reactive plan/run streams. (Bloc is an acceptable alternative.) |
| Local database | **Drift (SQLite)** | Typed, reactive queries that drive the UI automatically; ideal for plan + runs + history. |
| Health data | **`health` package → Health Connect** | Reads Samsung Health data that's synced into Health Connect. |
| Background sync | **`workmanager`** | Periodic background polling of Health Connect. |
| Notifications | **`flutter_local_notifications`** | Scheduled daily reminders + evening check-ins. |
| Charts | **`fl_chart`** | Weekly volume and long-run progression graphs. |
| Architecture | **Feature-first + clean layering** (data / domain / presentation, repository pattern) | Keeps the Adaptive Engine pure and unit-testable, isolated from Flutter/IO. |

> Use the **latest stable** version of each package at build time and verify current Health Connect API requirements — this space moves, so don't hard-code assumptions from this doc.

---

## 3. Data model

Use Drift tables. Core entities:

### TrainingPlan
| field | type | notes |
|---|---|---|
| id | int (pk) | |
| name | string | e.g. "Marathon — Nov 2026" |
| raceDate | date | **fixed anchor** |
| raceDistanceKm | double | 42.2 |
| startDate | date | |
| longRunDay | int | 1–7, preferred weekday for long runs |
| status | enum | active / completed / archived |
| createdAt | datetime | |

### PlannedRun
| field | type | notes |
|---|---|---|
| id | int (pk) | |
| planId | int (fk) | |
| scheduledDate | date | current scheduled date (mutable) |
| originalDate | date | where it *started* — for showing shifts |
| weekIndex | int | 1-based training week |
| type | enum | `easy` / `steady` / `long` / `rest` / `cross` / `strength` |
| targetDistanceKm | double? | null for rest/strength |
| targetDurationMin | int? | optional |
| runWalkRatio | string? | e.g. "4:1" (run 4 / walk 1) |
| priority | int | derived from type (see Engine) |
| status | enum | `pending` / `completed` / `missed` / `shifted` / `dropped` |
| notes | string? | |

### CompletedRun
| field | type | notes |
|---|---|---|
| id | int (pk) | |
| plannedRunId | int? (fk) | null if unplanned/extra run |
| date | date | |
| actualDistanceKm | double | |
| durationSec | int | |
| avgPaceSecPerKm | double | computed |
| avgHr | int? | |
| maxHr | int? | |
| calories | double? | |
| source | enum | `healthConnect` / `manual` |
| externalId | string? | Health Connect record id, for dedup |

### Settings
units (metric default), reminderTimeMorning, reminderTimeEvening, adaptivityAggressiveness (conservative / balanced / aggressive), catchupWindowDays, cloudBackupEnabled.

---

## 4. The Adaptive Scheduling Engine  ⭐ (the heart of the app)

This is the most important and highest-risk component. Implement it as a **pure Dart module** in `domain/` with **no Flutter or IO dependencies**, so it can be exhaustively unit-tested.

### 4.1 Philosophy: "smart redistribute, protect the race date"

The race date is immovable. Missed runs are not pushed forward indefinitely. Instead, the engine redistributes missed load across the remaining schedule **within safety guardrails**. If redistribution can't be done safely (too many misses, not enough runway), the engine **degrades the plan's ambition** (e.g. lowers the peak, drops low-value easy runs) rather than cramming unsafe volume — and warns the user.

### 4.2 Run priorities

- **Long run** → highest. Must be preserved; it's where the marathon is built.
- **Steady / medium** → medium. Reschedule if it fits safely; reduce or drop if not.
- **Easy / recovery** → low. Reschedule into a nearby free slot, otherwise drop (not worth injury risk).
- **Strength / cross / rest** → flexible/droppable.

### 4.3 Hard constraints (never violated)

1. **Min rest:** at least one easy/rest day between two hard runs; a long run is never scheduled the day after another run.
2. **Weekly load ceiling:** a week's total may not exceed `min(originalWeekTarget × 1.15, safeCeiling)`.
3. **Week-over-week jump:** total weekly volume must not increase more than ~15% vs the previous *completed* week (injury rule).
4. **Taper lock:** the final `taperWeeks` (default 3) are sacred. No increases. Missed taper runs are **dropped**, never redistributed forward.
5. **Peak long-run guard:** the peak long run (32km) must remain at least `taperWeeks` before the race. It is never pushed into the taper.
6. **Catch-up window:** a missed run can only be made up within `catchupWindowDays` (default 7; longer for long runs, default 10). Beyond that it expires/drops.

### 4.4 Soft objectives (optimize, but yield to hard constraints)

- Keep long runs on the user's preferred `longRunDay`.
- Keep total planned volume as close to the original as safely possible.
- Minimize disruption (move the fewest runs).

### 4.5 Algorithm (pseudocode)

```text
function onDayRollover(today):
    for run in plan.runsScheduledBefore(today) where status == pending:
        markMissed(run)
        reschedule(run, today)
    revalidateForwardSchedule(today)
    recomputeReadiness()

function reschedule(run, today):
    switch run.priority:
        case LOW:   // easy / recovery
            slot = findFreeSlot(from=today, window=catchupWindow, respectRest=true)
            if slot and weeklyLoadOk(slot.week, +run.distance):
                moveRun(run, slot)
            else:
                dropRun(run)

        case MEDIUM:  // steady
            slot = findFreeSlot(from=today, window=catchupWindow, respectRest=true)
            if slot and weeklyLoadOk(slot.week, +run.distance):
                moveRun(run, slot)
            else:
                fit = maxDistanceThatFits(slot)   // try a reduced version
                if fit >= 0.6 * run.distance: moveRun(run, slot, distance=fit)
                else: dropRun(run)

        case HIGH:   // long run — must preserve
            slot = findLongRunSlot(from=today, preferDay=settings.longRunDay,
                                   window=longCatchupWindow)
            if slot == null:
                degradePlan(run)        // see 4.6
            else:
                if collidesWithNextLongRun(slot):
                    rebalanceTwoLongRuns(run, nextLongRun)  // borrow within 15% rule
                moveRun(run, slot, displaceLowerPriorityRuns=true)

function weeklyLoadOk(week, delta):
    newTotal = week.plannedTotal + delta
    return newTotal <= min(week.originalTarget * 1.15, safeCeiling)
       and weekOverWeekJump(week) <= 0.15
```

### 4.6 When safe redistribution is impossible (`degradePlan`)

Surface a clear decision to the user with options:

- **Reduce the peak** — lower the remaining long-run targets to fit the runway safely.
- **Accept readiness risk** — keep the plan but flag that readiness is below target.
- **Drop low-value runs** — shed easy/strength sessions to make room for the long run.

The engine never silently creates unsafe weeks. It either fits within guardrails or asks.

### 4.7 Readiness score

Compute a 0–100 score from:
- % of *long-run* target volume completed (weighted heaviest),
- longest single run achieved vs target (32km),
- % of total planned volume completed,
- consistency (rolling completion rate).

Display as a dial with a short plain-language label ("On track", "Slightly behind", "At risk").

### 4.8 Required unit tests (write these first)

- Miss one easy run → it reschedules within the week or drops; weekly load unchanged beyond ceiling.
- Miss a long run → it moves to the next valid long-run slot; never lands the day after another run.
- Miss long runs two weeks running → two long runs rebalance without breaching the 15% week-over-week rule.
- Miss runs during taper → they drop; taper volume never increases.
- Cascade of misses near race day → engine triggers `degradePlan` and returns options rather than unsafe weeks.
- Catch-up window expiry → stale missed runs drop.

---

## 5. Plan generator

The app generates the plan from inputs, so the engine has structure to work with.

**Inputs:** raceDate, raceDistanceKm, currentLongestRunKm, daysPerWeek, preferredLongRunDay.

**Parameters (defaults):**
- `startLongRunKm` ≈ 0.55 × raceDistance, clamped to ≥ currentLongestRun − 4
- `peakLongRunKm` = 32
- `buildPattern` = 3 build weeks → 1 cutback week (cutback ≈ 0.7 ×)
- weekly long-run increase ≈ 2km on build weeks
- `taperWeeks` = 3, taper factor ~0.75, ~0.55, race
- 3 runs/week: Easy (short) + Steady (medium) + Long

**Default seed (the user's actual 19-week plan — use as the starting template, long-run km):**

```
W1:14  W2:16  W3:19  W4:14(cutback)  W5:21  W6:23  W7:18(cutback)
W8:25  W9:27  W10:20(cutback)  W11:28  W12:30  W13:22(cutback)
W14:31  W15:32(PEAK)  W16:24  W17:19  W18:13  W19:RACE 42.2
```

Easy day ≈ 5–7km, Steady day scales 8→16km then eases into taper. Encode the generator so changing the race date reflows the whole plan and the taper re-anchors to race day.

---

## 6. Health Connect integration

**Data path:** Samsung Health (watch) → Health Connect → app via `health` package.

- **User setup (document in onboarding):** install Health Connect (or use the built-in version on Android 14+), install Samsung Health, and enable Samsung Health → Health Connect data sync.
- **Permissions (READ):** ExerciseSession (workouts), Distance, TotalCaloriesBurned / ActiveCaloriesBurned, HeartRate, Steps.
- **Sync logic:** on each sync, fetch ExerciseSessions of type running/walking since the last sync timestamp. For each session, dedup by `externalId`, compute distance/duration/pace/avg+max HR, and **match it to the PlannedRun on that date** (nearest pending run that day; if none, store as an extra/unplanned run). Mark matched PlannedRun `completed`.
- **Manual fallback:** always allow manual run entry (watch dead, forgot it, etc.).
- **Publishing note:** if ever shipped on Google Play, Health Connect data access needs the Play declaration/review. For personal sideloading this is not required — but state the manifest permission declarations regardless.

---

## 7. Notifications & background sync

- **Morning reminder** at `reminderTimeMorning`: today's prescribed run (type, distance, run-walk ratio) — or a rest-day note.
- **Evening check** at `reminderTimeEvening`: if today's run is still `pending`, prompt with two actions → **"Mark done / log"** or **"Couldn't run today"** (the latter triggers the engine immediately so the user sees the reshuffle).
- **Post-sync confirmation:** "12.3km logged — you're 68% through this week."
- **Weekly summary** (Sunday evening): volume vs target, readiness trend.
- **Background sync:** `workmanager` polls Health Connect a few times daily; respect Android background limits and battery optimization (guide the user to whitelist the app).

---

## 8. Screens

1. **Onboarding / plan setup** — race date, distance, current longest run, days/week, long-run day, reminder times → generates plan. Health Connect permission flow + Samsung Health sync explainer.
2. **Today (home)** — today's run card with type, target, run-walk ratio; actions: *Start / Mark complete / Couldn't run today*. Today's readiness glance.
3. **Plan / calendar** — week & month views, runs color-coded by status; shifted runs visually show their move (original → new date).
4. **Run detail** — target vs actual after sync (distance, pace, HR, calories); notes.
5. **Progress / stats** — weekly volume bar chart, long-run progression line, readiness dial, completion streak.
6. **Sync status** — last sync, Health Connect permission state, manual "sync now".
7. **Settings** — reminders, units, adaptivity aggressiveness, catch-up window, cloud backup toggle.

When the engine reshuffles, show a clear, friendly summary: *"Moved Saturday's 28km long run to Sunday; shortened Tuesday's easy run to keep your week safe."*

---

## 9. Project structure (feature-first)

```
lib/
  core/            (theme, constants, utils, result types)
  data/
    db/            (Drift tables, DAOs)
    health/        (Health Connect service + mappers)
    repositories/  (plan, runs, settings)
  domain/
    models/        (pure entities)
    engine/        (AdaptiveScheduler — pure, fully tested)
    plan_generator/(pure plan builder)
    readiness/     (scoring)
  presentation/
    today/  plan/  run_detail/  stats/  onboarding/  settings/
    widgets/
  services/        (notifications, background workmanager)
  main.dart
test/
  engine/          (the priority test suite)
  plan_generator/
```

---

## 10. Build phases (do in order)

- **Phase 1 — Foundation:** scaffold, Drift schema, plan generator, manual run logging, calendar + today screens. App is usable without the watch.
- **Phase 2 — Adaptive Engine:** implement the pure scheduler + readiness; write the full test suite from §4.8 *first*; wire "Couldn't run today" to it.
- **Phase 3 — Health Connect:** permissions, sync, session→run matching, dedup, manual fallback.
- **Phase 4 — Notifications & background sync:** reminders, evening check, post-sync, weekly summary, workmanager polling.
- **Phase 5 — Stats & polish:** charts, readiness dial, shift summaries, settings, empty/error states.
- **Phase 6 (optional) — Cloud backup:** Firebase (Firestore) export/restore behind the settings toggle.

---

## 11. Acceptance criteria

- Generating a plan from a race date produces a structured 3-day/week schedule that tapers correctly into race day.
- Marking a run "couldn't do today" reshuffles forward within all §4.3 guardrails and shows a plain-language summary.
- A real watch run appears in the app after sync, matched to the right planned run, with pace/HR populated.
- Reminders fire at the configured times; the evening check correctly detects an incomplete run.
- The engine's full unit-test suite (§4.8) passes.
- The app runs offline; Health Connect/cloud are enhancements, not hard dependencies.

---

## 12. Instructions to Claude Code

- Build **phase by phase**; keep the `domain/engine` and `domain/plan_generator` modules pure (no Flutter imports) so they stay unit-testable.
- Write the engine's tests **before** its UI wiring.
- Use latest stable package versions; verify current Health Connect API + permission requirements at build time rather than trusting versions named here.
- Prefer clear, well-named functions over cleverness in the engine — correctness and testability beat brevity.
- After each phase, confirm the app builds and runs, then summarize what changed before continuing.
