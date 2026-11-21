# CleanLog — plan and status

The living checklist. A fresh session reads this first, takes the branch marked **NEXT**, works on
that branch only, updates this file, and stops. Rules: `CLAUDE.md` (Branches and sessions).

## How a session runs

1. `git switch <branch>` (create it from its base when the table says so).
2. Read the branch's tasks in the plan file and the spec it points to.
3. **Implement** (if the branch is not built yet): the plan's steps, test-first, one commit per task.
4. **Review** the branch diff (`git diff <base>...HEAD`): `swift-concurrency-pro` and/or `swiftui-pro`
   as the table says, then the SOLID / clean-code pass and every rule in `.claude/conventions/`.
   Fix findings in new commits on the same branch.
5. Build, test, `xcrun swift-format lint --strict --recursive CleanLog CleanLogTests` — all green.
6. If the review changed code, merge this branch into every later branch of the stack that already
   exists (`git switch <later> && git merge <this>`) and build it; its tests run in its own session.
   Never rebase.
7. Update the table below (status, review result), push the branch, open its PR with `gh pr create`
   (base = the branch's base; description as in `CLAUDE.md` → Git), stop.

## Feature 1 — Foundation

Plan: `docs/superpowers/plans/2026-11-20-foundation.md` · Spec: `docs/superpowers/specs/2026-11-20-foundation-design.md`

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 1 | `feature/CL-1-test-target-day-keys` | `main` | 1–2 | 481 | merged (PR #1) | done — concurrency clean; SOLID: 3 fixes + convention sync (below) |
| 2 | `feature/CL-2-apartment-workday` | `main` | 3–4 | 469 | merged (PR #2) | done — concurrency clean; SOLID: 5 fixes (below) |
| 3 | `feature/CL-3-timer-stats` | `main` | 5–6 | 353 | merged (PR #3) | done — concurrency clean; SOLID: 6 fixes (below) |
| 4 | `feature/CL-4-report-formatters` | `main` | 7–8 | 294 | merged (PR #4) | done — concurrency clean; SOLID: 5 fixes + spec sync (below) |
| 5 | `feature/CL-5-repositories` | `main` | 9 | 504 | merged (PR #5) | done — concurrency: 1 test fix; SOLID: 1 fix (below) |
| 6 | `feature/CL-6-swiftdata` | `main` | 10 | 563 | reviewed, PR open | done — concurrency clean; SOLID: 3 fixes (below) |
| 7 | `feature/CL-7-app-wiring` | 6 | 11 | ~150 est. (end of feature) | to do (create from 6, or `main` once 6 is merged) | **NEXT** — after build — `swiftui-pro` + SOLID |

Notes for the sessions:

- Branches 1–4 were built in one long session before the branch rules existed; their review has not
  run yet. Review each one in its own fresh session, in order.
- CL-1 review (2026-11-21): `main` merged in for the current conventions. Concurrency: no
  findings (`nonisolated` structs keep their conformances off the main actor). SOLID / clean code:
  `DayKey(_:calendar:)` failed silently to day 0 → `preconditionFailure`; `MonthKey` storage
  bounds duplicated the `yyyymmdd` encoding → derived from `DayKey.storageValue`; the Warsaw test
  calendar fell back to the device time zone → fails instead; `architecture.md` DayKey/Date
  sentence updated as the foundation spec requires. Merged up into CL-2…CL-5 (CL-2–4 tests green).
- CL-2 review (2026-11-21): PR #1 was merged into `main`, so CL-2's PR targets `main`. Concurrency:
  no findings. SOLID / clean code: `ApartmentError` moved to its own file (the repositories use
  `.notFound`, it is not the draft's supporting type); `validated(against:excluding:)` split into
  `isName(_:takenIn:excluding:)` and `normalizedAccessCode`; `DayEntry`'s hand-written memberwise
  init removed (the snapshot init moved to an extension); `settingCleaned(_:to:now:today:)` labels
  the flag and `appending` became `addingUnplanned`; the unused `accessCode` fixture parameter
  dropped; test calls with 3+ arguments put one per line. Kept: `WorkDayError.notToday` and
  `.timerState` are unused in CL-2 but belong to the timer rules in CL-3. Merged up into CL-3…CL-5;
  CL-5's contract tests updated to the new label; CL-3 and CL-4 build with their tests.
- CL-3 review (2026-11-21): PR #2 was merged into `main`, so `main` was merged in and CL-3's PR
  targets `main`. Concurrency: no findings (pure synchronous values, `nonisolated` like CL-2's
  planning extension). SOLID / clean code: `MonthStats.calculate` split into `earningsPerHour` and
  `average(of:over:)` and each day's worked duration computed once; the per-hour `3600` named
  `secondsPerHour`; `topApartments` tallies instead of `entries.last?.name ?? ""` over a group that
  is never empty; the three `.notToday` guards became `requireToday(_:)`; packed 3-argument
  `WorkSession` / `ApartmentCount` calls put one argument per line; the rounding test parameterized.
  Merged up into CL-4 and CL-5 (both build; CL-4's tests run in its own session).
- CL-4 review (2026-11-21): PR #3 was merged into `main`, so `main` was merged in and CL-4's PR
  targets `main`. Concurrency: no findings (pure `nonisolated` formatters; the report calendar is a
  `Sendable` static). SOLID / clean code: the report's `firstWeekday = 2` was set but unused (weeks
  came from `(weekday + 5) % 7`) → weeks now come from `dateInterval(of: .weekOfYear)` on that
  calendar; `report(for:days:)` split into `workedDays`, `weeks(of:)` and `date(of:)`, dropping the
  `weeks[week] ?? []` over a group that is never empty; `TimeZone(secondsFromGMT: 0) ?? .gmt` →
  `.gmt`; `DurationFormat`'s `3600`/`60` and `MoneyFormat`'s `100`/`"zł"` named; the two copies of
  "plan these and tick them" in the report tests became `WorkDay.fixture(_:ticked:unticked:)` in
  `Support/Fixtures.swift`, and the October fixture's `?? 0` day became a `preconditionFailure`.
  Kept: the October input is parsed from the expected text instead of a second 31-line table (the
  input is shuffled, so the order and counts are still the builder's work). Product spec: report
  weeks always start on Monday (the foundation spec required this sync). Merged up into CL-5.
- CL-5 (2026-11-21): PR #4 was merged into `main`, so `main` was merged in and CL-5's PR targets `main`.
  Built from the drafted contract tests. Deviation from the plan interface: `StoreObservers` is not generic
  — one per repository, generic per `stream`, so one `notify()` after a save reaches both the day and the
  month streams (plan file updated). Added domain helpers both repositories need, test-first:
  `Apartment(_:sortOrder:createdAt:)`, `Apartment.applying(_:)`, `WorkDay.isBlank` (a day with only a
  manual duration is not blank). Concurrency review: `StoreObservers` is main-actor; `onTermination` hops
  with `Task { @MainActor in … }` because it can fire off the main actor; a yield into an ended stream
  between cancellation and removal is harmless; `[unowned self]` in the fakes is safe because only the
  repository's own `StoreObservers` calls the read closure; no `await` between read and write, so no
  reentrancy. Finding fixed: `survivesACancelledObserver` subscribed inside the task after a
  `Task.yield()`, so it could pass without ever subscribing → the stream is created before the task.
  SOLID / clean code: packed 3+-argument declarations and calls (the new `Apartment` init, its test,
  the contract tests' `draft`) put one argument per line; `DayKey(year:month:day:)` and `Date.warsaw`
  literals stay packed like the rest of the tests. Size 504: 4 over the cap only from that formatting,
  not split. Kept: apartments with equal `sortOrder` (an archived one after a partial `reorder`) have no
  tie-break — the UI always reorders the whole active list; revisit in the Apartments feature.
- CL-6 (2026-11-21): PR #5 was merged, so CL-6 starts from `main` and its PR targets `main`.
  Deviations from the plan (plan file and `architecture.md` updated): the SwiftData repositories take
  the `ModelContainer`, not a `ModelContext` — a context does not keep its container alive, and the
  contract tests (`kind.makeStore().workDays`) dropped the store at once and crashed in `fetch`, so
  `StoreUnderTest.keepAlive` is gone; `DayEntryRecord` and `WorkSessionRecord` carry `position`,
  because a to-many relationship comes back unordered; `ModelContainerFactory` sets
  `cloudKitDatabase: .none` until sync is a decision. A failed save rolls the context back
  (`ModelContext.saveOrRollBack`). A failed read in a stream is logged and yields the empty value
  (`[]`, `.empty(day)`); writes still throw. Concurrency review: the `@Model` records and their
  mapping extensions come out nonisolated under default `MainActor` isolation (the compiler said so),
  so the `ModelContext` sync and insert helpers are `nonisolated` too; records are only touched
  through the main context by main-actor repositories, nothing is `Sendable`-forced; no `await`
  inside the repositories, so no reentrancy. No findings. SOLID / clean code: the next sort order was
  computed in both apartment repositories → `Apartment.nextSortOrder(after:)`, test-first; "create a
  record and insert it" in three places → `ModelContext.inserted(_:)`; 3-argument calls (`synced`,
  `WorkSession` in tests) put one argument per line. Kept: the do/catch-log-fallback in the three
  stream reads — each has its own fallback and message. Size 563 (about 540 code and tests): over
  the cap, kept as one branch by the user's decision — one feature, partly from formatting.
- Branch 4 is under 300 lines on purpose: it closes the pure-logic half of the foundation.
- After branch 7 merges: delete the foundation plan and design files (`CLAUDE.md`), mark the feature
  done here.

Next free branch number: **CL-8**.

## Roadmap (v1)

Each feature: brainstorm → plan (split into 300–500-line branches, written here) → plan review →
branches as above.

1. Foundation — in progress (above).
2. Design system — colour tokens, `.glassSurface`, `.cardSurface`, String Catalog, the `TabView` shell.
3. Apartments (template) — list, form, reorder, archive. Logic, then UI.
4. Today — plan, ticks, timer, empty state, "as yesterday", past and future days. Logic, then UI.
5. Day plan sheet. Logic, then UI.
6. Calendar. Logic, then UI.
7. Statistics. Logic, then UI.
8. Report and WhatsApp. Logic, then UI.
9. Settings and reminders. Logic, then UI.
10. First launch, app icon, Bundle ID, privacy policy, TestFlight.

Later: Live Activity, home-screen widget, iCloud sync, PDF/CSV export.
