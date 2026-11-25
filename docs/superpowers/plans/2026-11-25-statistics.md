# Statistics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Statistics tab: a month's earnings, the change against the previous month, four cards and the
most frequent apartments, following the store.

**Architecture:** `MonthStats` (pure, `Models/`) learns to count a day's time only once its work is over;
`EarningsChange` (pure) compares two months; `StatsSummary` (presentation, `Features/Stats/`) formats both;
`StatsViewModel` observes the shown and the previous month and rebuilds the summary; `StatsView` lays it out.

**Tech Stack:** SwiftUI, Swift Testing, String Catalog with generated symbols. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-11-25-statistics-design.md` (product spec: Statistics).

## Global Constraints

- iOS 18.0+, Swift 6, default `MainActor` isolation; every type in `Models/` and `Formatting/` is `nonisolated`.
- Money is `Money(minorUnits:)`; percentages and rates in integer arithmetic, rounded half up.
- Every user-facing string is a `stats.*` catalog key with Ukrainian and English; counts are plurals.
- Tests pin `today`, `Calendar` (`.warsaw`) and `Locale` (`uk_UA`, one `en_US` case per formatter).
- No comments in Swift; one argument per line for 3+ arguments; `swift-format lint --strict` clean.
- The «Звіт» button is **not** part of this feature.

## Review Focus

- A finished month that earned nothing after a month that earned → no badge (Task 4 test
  `hidesTheChangeWhenTheMonthEarnedNothing`).
- Today paused (not finished) mid-day → its time and its earnings stay out of «За годину» (Task 1 test
  `todayPausedCountsNothing`, Task 5 test `leavesTodaysUnfinishedTimeOut`).
- A past day whose overrun timer was not dropped yet → no time at all, not its closed sessions (Task 1 test
  `pastDayWithAnOpenSessionCountsNothing`).
- Paging right after a month's numbers arrived → the new month never shows the old month's numbers
  (Task 5 test `pagingClearsTheOldMonth`).
- The app left open across the first of a month → the shown month stays, › becomes available and the
  finished month gains its badge (Task 5 test `advancingIntoANewMonthKeepsTheShownMonth`).

## Branches

| CL | Branch | Base | Tasks |
|---|---|---|---|
| 36 | `feature/CL-36-statistics-spec` | `main` | — (spec, this plan, product spec; deletes the Calendar plan) |
| 37 | `feature/CL-37-statistics-logic` | CL-36 (or `main` once merged) | 1–3 |
| 38 | `feature/CL-38-statistics-summary` | CL-37 | 4 |
| 39 | `feature/CL-39-statistics-view-model` | CL-38 | 5 |
| 40 | `feature/CL-40-statistics-screen` | CL-39 | 6 |

Reviews: CL-37, CL-38 — SOLID / clean code; CL-39 — `swift-concurrency-pro` + SOLID; CL-40 — `swiftui-pro` +
SOLID. If a branch's estimate is off, move the boundary and record it in `docs/plan.md`.

---

### Task 1: Count a day's time only once its work is over

**Files:**
- Modify: `CleanLog/Models/WorkDay/WorkDay+Timer.swift`, `CleanLog/Models/MonthStats.swift`,
  `CleanLog/Features/Today/DaySummary.swift`, `CleanLog/Features/Today/DayViewModel.swift` (the
  `DaySummary(` call)
- Test: `CleanLogTests/Models/WorkDayTimerTests.swift`, `CleanLogTests/Models/MonthStatsTests.swift`, the
  `DaySummary` tests under `CleanLogTests/Features/Today/`

**Interfaces:**
- Produces: `WorkDay.countedDuration(today: DayKey) -> Duration?`;
  `MonthStats.calculate(days: [WorkDay], today: DayKey) -> MonthStats` (replaces `calculate(days:now:)`);
  `DaySummary.init(_:kind:month:calendar:locale:)` (the `now:` parameter is gone).

- [ ] **Step 1: Write the failing tests** in `WorkDayTimerTests` (today = 2026-11-25; build sessions with
  `WorkSession(id:start:end:)` from `Date.warsaw`):
  - `manualDurationAlwaysCounts`: a day with `manualDuration = .seconds(3600)` and an open session →
    `.seconds(3600)`;
  - `pastDayCountsItsClosedSessions`: Nov 24, sessions 8–10 and 11–12, not finished → `.seconds(3 * 3600)`;
  - `pastDayWithAnOpenSessionCountsNothing`: Nov 24, 8–10 closed, 11–nil → `nil`;
  - `todayRunningCountsNothing`: Nov 25, 8–nil → `nil`;
  - `todayPausedCountsNothing`: Nov 25, 8–10 closed, `isTimerFinished == false` → `nil`;
  - `todayFinishedCountsItsSessions`: Nov 25, 8–10, `isTimerFinished == true` → `.seconds(2 * 3600)`;
  - `dayWithoutTimeCountsNothing`: `WorkDay.empty(Nov 24)` → `nil`.

  In `MonthStatsTests`: replace `now` with `private let today = DayKey(year: 2026, month: 11, day: 30)`
  and every `calculate(days:now:)` with `calculate(days:today:)` (all existing expectations stay); add
  `todayUnfinishedTimeStaysOutOfThePerHourRate`: Nov 1 earns 28 zł with 1 h; today (Nov 30) earns 56 zł with
  a running session from 8:00 → `workedDuration == .seconds(3600)`, `earningsPerHour == Money(minorUnits: 2800)`,
  `earned == Money(minorUnits: 8400)`, `averagePerWorkingDay == Money(minorUnits: 4200)`.

- [ ] **Step 2: Run them, expect a compile failure** (`countedDuration` and `calculate(days:today:)` missing):
  `xcodebuild … test -only-testing:CleanLogTests/WorkDayTimerTests -only-testing:CleanLogTests/MonthStatsTests`

- [ ] **Step 3: Implement.** `countedDuration(today:)` in `WorkDay+Timer.swift`, in this order: a manual
  duration → it; an open session → `nil`; no sessions → `nil`; `day < today || isTimerFinished` → the sum of
  the closed sessions; otherwise `nil`. `MonthStats.calculate(days:today:)` uses `countedDuration(today:) ?? .zero`
  where it used `workedDuration(now:)`; `earningsPerHour` keeps its "worked > 0" filter. `DaySummary` calls
  `calculate(days: month, today: workDay.day)` (its `.today` case is the only caller) and drops `now`;
  `DayViewModel` and the `DaySummary` tests drop the argument.

- [ ] **Step 4: Run the full test suite, expect PASS.**

- [ ] **Step 5: Commit** — `Count a day's time in statistics only once its work is over`

### Task 2: Compare a month's earnings with the previous month

**Files:**
- Create: `CleanLog/Models/EarningsChange.swift`
- Test: `CleanLogTests/Models/EarningsChangeTests.swift`

**Interfaces:**
- Produces:
  ```swift
  nonisolated struct EarningsChange: Sendable, Equatable {
      enum Direction: Sendable, Equatable { case up, down, same }
      let direction: Direction
      let percent: Int
      static func between(current: Money, previous: Money) -> EarningsChange?
  }
  ```

- [ ] **Step 1: Write the failing tests** (amounts in minor units):
  - `risesByARoundedPercent`: 201600 vs 185000 → `.up`, 9;
  - `fallsByARoundedPercent`: 150000 vs 170000 → `.down`, 12;
  - `roundsHalfUp`: 100500 vs 100000 → `.up`, 1;
  - `equalIsTheSame`: 100000 vs 100000 → `.same`, 0;
  - `aChangeThatRoundsToZeroIsTheSame`: 100001 vs 100000 → `.same`, 0;
  - `isNilWhenThePreviousMonthEarnedNothing`: 100000 vs 0 → `nil`;
  - `isNilWhenThisMonthEarnedNothing`: 0 vs 100000 → `nil`.

- [ ] **Step 2: Run, expect a compile failure.**

- [ ] **Step 3: Implement** `between(current:previous:)`: `nil` unless both are above zero;
  `percent = (|current − previous| · 100 · 2 + previous) / (previous · 2)` (the half-up division
  `MonthStats` uses); `.same` when `percent == 0`, else by sign.

- [ ] **Step 4: Run `EarningsChangeTests`, expect PASS.**

- [ ] **Step 5: Commit** — `Add the month-on-month earnings change`

### Task 3: Format worked hours and a month inside a phrase

**Files:**
- Modify: `CleanLog/Formatting/DurationFormat.swift`, `CleanLog/Formatting/DayFormat.swift`
- Test: `CleanLogTests/Formatting/DurationFormatTests.swift`, `CleanLogTests/Formatting/DayFormatTests.swift`

**Interfaces:**
- Produces: `DurationFormat.hoursAndMinutes(_ duration: Duration, locale: Locale) -> String`;
  `DayFormat.monthInPhrase(_ month: MonthKey, calendar: Calendar, locale: Locale) -> String`.

- [ ] **Step 1: Write the failing tests** (values checked against Foundation on 2026-11-25):
  - `formatsWorkedHours`: `uk_UA`: 62 h 15 min → `"62 год, 15 хв"`, 62 h → `"62 год"`, `.zero` → `"0 год"`,
    59 s → `"0 год"`, 61 min 59 s → `"1 год, 1 хв"`; `en_US`: 62 h 15 min → `"62 hr, 15 min"`, `.zero` → `"0 hr"`.
  - `formatsAMonthInsideAPhrase`: October 2026, `.warsaw`: `uk_UA` → `"жовтня"`, `en_US` → `"October"`.

- [ ] **Step 2: Run, expect a compile failure.**

- [ ] **Step 3: Implement.** `hoursAndMinutes`: truncate to whole minutes first (Foundation rounds 59 s up to
  «1 хв»); under one minute format with `allowedUnits: [.hours]`, otherwise `[.hours, .minutes]`, both
  `Duration.UnitsFormatStyle(…, width: .abbreviated)` with the locale. `monthInPhrase`: the format-context
  wide month of the month's first day, `Date.VerbatimFormatStyle("\(month: .wide)", locale:timeZone:calendar:)`
  — in Ukrainian that is the genitive «жовтня» that «до …» needs.

- [ ] **Step 4: Run both suites, expect PASS.**

- [ ] **Step 5: Commit** — `Add the worked-hours and in-phrase month formatters`

**End of CL-37.** Build, full tests, lint; review; record in `docs/plan.md`; PR.

### Task 4: The statistics summary and its strings

**Files:**
- Create: `CleanLog/Features/Stats/StatsSummary.swift` (with `StatsApartmentRow` above it)
- Modify: `CleanLog/Resources/Localizable.xcstrings`
- Test: `CleanLogTests/Features/Stats/StatsSummaryTests.swift`

**Interfaces:**
- Consumes: `MonthStats`, `EarningsChange.between`, `DurationFormat.hoursAndMinutes`, `DayFormat.monthInPhrase`,
  `MoneyFormat.string`.
- Produces:
  ```swift
  struct StatsApartmentRow: Equatable, Identifiable {
      let id: UUID
      let name: String
      let countText: String
      let barFraction: Double
  }
  struct StatsSummary: Equatable {
      let earnedText: String
      let changeText: String?
      let cleanedText: String
      let workedText: String
      let perHourText: String
      let perDayText: String
      let workingDaysText: String
      let topApartments: [StatsApartmentRow]
      var hasCleanedApartments: Bool
  }
  extension StatsSummary {
      init(stats: MonthStats, previousEarned: Money?, month: MonthKey, isFinished: Bool,
           calendar: Calendar, locale: Locale)
  }
  ```
  (`hasCleanedApartments` is `!topApartments.isEmpty`.)

Catalog keys (Ukrainian / English; model the argument keys on `calendar.card.earned`):

| Key | uk | en |
|---|---|---|
| `stats.change.up` (percent, month) | ↑ %lld%% до %@ | ↑ %lld%% vs %@ |
| `stats.change.down` (percent, month) | ↓ %lld%% до %@ | ↓ %lld%% vs %@ |
| `stats.change.same` (month) | 0% до %@ | 0% vs %@ |
| `stats.value.none` | — | — |
| `stats.top.count` (plural) | %lld раз / рази / разів | %lld time / times |
| `stats.top.workingDays` (plural) | %lld робочий день / робочі дні / робочих днів | %lld working day / days |
| `stats.earned.title` | Заробіток | Earned |
| `stats.card.cleaned` | Квартир прибрано | Apartments cleaned |
| `stats.card.worked` | Робочий час | Hours worked |
| `stats.card.perHour` | За годину | Per hour |
| `stats.card.perDay` | Середньо за день | Average per day |
| `stats.top.title` | Найчастіші квартири | Most frequent |
| `stats.empty` | Цього місяця ще нічого не прибрано | Nothing cleaned this month yet |

The last six are used only by the view (Task 6) but ship here so the catalog changes once.

- [ ] **Step 1: Write the failing tests** (`uk_UA`, `.warsaw`, November 2026; build `MonthStats` with its
  memberwise initializer; `\u{00A0}` is the no-break space `MoneyFormat` uses):
  - `formatsAFinishedMonth`: earned 201600, cleaned 63, worked 62 h 15 min, per hour 3300, per day 16800,
    12 working days, top 100 ×10, 102 ×10, 101 ×9; previous 185000; finished →
    `earnedText == "2\u{00A0}016\u{00A0}zł"`, `changeText == "↑ 9% до жовтня"`, `cleanedText == "63"`,
    `workedText == "62 год, 15 хв"`, `perHourText == "33\u{00A0}zł"`, `perDayText == "168\u{00A0}zł"`,
    `workingDaysText == "12 робочих днів"`, counts `["10 разів", "10 разів", "9 разів"]`, fractions `[1, 1, 0.9]`.
  - `showsADropAndNoChange`: 150000 vs 170000 → `"↓ 12% до жовтня"`; 100000 vs 100000 → `"0% до жовтня"`.
  - `hidesTheChangeOnTheCurrentMonth`: as the first, `isFinished: false` → `changeText == nil`.
  - `hidesTheChangeUntilThePreviousMonthArrives`: `previousEarned: nil` → `nil`.
  - `hidesTheChangeWhenTheMonthEarnedNothing`: `MonthStats.calculate(days: [], today:)`, previous 100000,
    finished → `changeText == nil`, and `earnedText == "0\u{00A0}zł"`, `cleanedText == "0"`,
    `workedText == "0 год"`, `perHourText == "—"`, `perDayText == "—"`, `hasCleanedApartments == false`.
  - `namesTheMonthBeforeJanuary`: January 2027, previous earned → change text ends with `"до грудня"`.
  - `pluralizesCounts`: 1, 3 and 5 working days → `"1 робочий день"`, `"3 робочі дні"`, `"5 робочих днів"`;
    a row with count 1 → `"1 раз"`.
  - `formatsInEnglish`: `en_US`, the first case → `changeText == "↑ 9% vs October"`.

- [ ] **Step 2: Run, expect a compile failure.**

- [ ] **Step 3: Add the catalog keys, implement `StatsSummary.init`.** The change is formatted only when
  `isFinished`, `previousEarned` is non-nil and `EarningsChange.between` is non-nil; its month is
  `DayFormat.monthInPhrase(month.previous, …)`. `barFraction` is `count / topApartments[0].count`.

- [ ] **Step 4: Run `StatsSummaryTests`, expect PASS.**

- [ ] **Step 5: Commit** — `Add the statistics summary and its strings`

**End of CL-38.**

### Task 5: The statistics view model

**Files:**
- Create: `CleanLog/Features/Stats/StatsViewModel.swift`
- Test: `CleanLogTests/Features/Stats/StatsViewModelTests.swift`

**Interfaces:**
- Consumes: `WorkDayRepository.days(in:)`, `StatsSummary.init`, `MonthStats.calculate(days:today:)`,
  `DayFormat.monthAndYear`.
- Produces:
  ```swift
  @Observable @MainActor final class StatsViewModel {
      init(today: DayKey, workDays: any WorkDayRepository, calendar: Calendar = .current, locale: Locale = .current)
      private(set) var shownMonth: MonthKey
      private(set) var monthTitle: String
      private(set) var summary: StatsSummary
      var canShowNextMonth: Bool
      func showPreviousMonth()
      func showNextMonth()
      func advance(to today: DayKey)
      func observeMonth() async
      func observePreviousMonth() async
  }
  ```

Shape (Claude's call, mirrors `CalendarViewModel`): two observations, each started by its own
`.task(id: shownMonth)` in the view, rather than one task group — SwiftUI restarts and cancels each, and
the `where month == shownMonth` guard drops a late yield. The spec's "one task group" wording is updated with
this plan.

- [ ] **Step 1: Write the failing tests** (today = 2026-11-25, `FakeWorkDayRepository`, `.warsaw`, `uk_UA`;
  start an observation as `CalendarViewModelTests.observingMonth` does and wait with `eventually`):
  - `opensOnTheCurrentMonth`: `shownMonth == Nov 2026`, `monthTitle == "Листопад 2026\u{202F}р."`,
    `canShowNextMonth == false`.
  - `goesNoFurtherThanTheCurrentMonth`: `showNextMonth()` keeps November; `showPreviousMonth()` → October and
    `canShowNextMonth == true`; `showNextMonth()` → November.
  - `summarizesTheShownMonth`: Nov 3 ticked a100, a101 → `summary.cleanedText == "2"`,
    `summary.earnedText == "56\u{00A0}zł"`.
  - `showsTheChangeOnAFinishedMonth`: October earns 56 zł, September 28 zł; page to October, observe both →
    `summary.changeText == "↑ 100% до вересня"`.
  - `hidesTheChangeOnTheCurrentMonth`: November and October both earn, observe both → `changeText == nil`.
  - `pagingClearsTheOldMonth`: observe November with data, then `showPreviousMonth()` → at once
    `summary.cleanedText == "0"` and `changeText == nil`.
  - `followsATick`: tick an unticked entry through `workDays.update` → `cleanedText` goes from `"1"` to `"2"`.
  - `leavesTodaysUnfinishedTimeOut`: Nov 25 ticked with a running session from 8:00 →
    `workedText == "0 год"`, `perHourText == "—"`.
  - `advancingIntoANewMonthKeepsTheShownMonth`: `advance(to: Dec 1)` → `shownMonth` stays November,
    `canShowNextMonth == true`; with November and October earning and both observed, `changeText` appears.

- [ ] **Step 2: Run, expect a compile failure.**

- [ ] **Step 3: Implement.** Stored `shownDays: [WorkDay]` and `previousEarned: Money?`; a private
  `refresh()` rebuilds `monthTitle` and `summary` (`isFinished: shownMonth < today.monthKey`). Paging sets
  `shownDays = []`, `previousEarned = nil`, then refreshes. Both observations capture the **shown** month
  (`let month = shownMonth`) and guard with `where month == shownMonth`, the assignment right after the guard
  with no suspension between (as `CalendarViewModel.observeMonth`); `observePreviousMonth` streams
  `days(in: month.previous)` and stores `days.map(\.earned).sum()` — it must not capture `shownMonth.previous`,
  or the guard could never match. The tests start both observations in one helper and cancel both on exit. `showNextMonth()` does nothing unless `canShowNextMonth`.

- [ ] **Step 4: Run `StatsViewModelTests`, expect PASS.**

- [ ] **Step 5: Commit** — `Add the statistics view model`

**End of CL-39.**

### Task 6: The Statistics screen

**Files:**
- Modify: `CleanLog/Features/Stats/StatsView.swift`, `CleanLog/App/RootView.swift`,
  `CleanLog/UICommons/Badge.swift`, `CleanLog/Resources/Localizable.xcstrings`
- Create: `CleanLog/Features/Stats/StatsPreviewData.swift` (`#if DEBUG`)

**Interfaces:**
- Consumes: `StatsViewModel` (Task 5), `StatsSummary`, `StatsApartmentRow` (Task 4).
- Produces: `StatsView(workDays: any WorkDayRepository)`; `Badge(text: String)` beside the existing
  `Badge(title:)`.

New keys: `stats.month.previous` «Попередній місяць» / «Previous month», `stats.month.next` «Наступний
місяць» / «Next month».

- [ ] **Step 1: Build the screen** per the spec's "The screen" and the `Stats` artboard: a `ScrollView` under
  the navigation title `tab.stats.title`; a month switcher (two `StepButton`s around `monthTitle` in a
  `.glassSurface(.capsule)`, › `.disabled(!canShowNextMonth)`); the earnings card (`.cardSurface()`,
  `.largeTitle` rounded monospaced amount, `Badge(text:)` for `changeText`, one combined accessibility
  element); the four value cards in a two-column `Grid`, one column at `dynamicTypeSize.isAccessibilitySize`;
  the top-apartments heading with `workingDaysText` and a card of rows (bar `accessibilityHidden`, row
  combined) or the `stats.empty` line when `!hasCleanedApartments`. Each subview is a `struct` in the file;
  numbers in a `Layout` enum; the backdrop stays as it is.
- [ ] **Step 2: Wire the lifecycle.** `StatsView.init(workDays:)` builds the view model with
  `today: DayKey(.now, calendar: .current)`; `.task(id: viewModel.shownMonth)` once for `observeMonth()` and once for
  `observePreviousMonth()`; on `scenePhase` becoming `.active`, a private `advanceToCurrentDay()` method (not inline in `onChange`, as
  `TodayView` does it) calls `viewModel.advance(to: DayKey(.now, calendar: .current))`. The arrows pass the view
  model's methods as `StepButton`'s `action` directly.
  `RootView` passes `dependencies.workDays`.
- [ ] **Step 3: Preview** with `StatsPreviewData` (a November and an October of fixture days in a
  `FakeWorkDayRepository`), light and dark.
- [ ] **Step 4: Build, run the full tests and lint, expect green;** check on the iPhone 16 simulator in light,
  dark and at `accessibility5` against the artboard.
- [ ] **Step 5: Commit** — `Build the Statistics screen`

**End of CL-40 and of the feature.**

## Plan review (2026-11-25)

- `swift-concurrency-pro`: one fix, folded into Task 5 — both observations capture the shown month and guard
  on it; `observePreviousMonth` must not capture `shownMonth.previous`. Otherwise clean: no stored tasks, the
  `.task(id:)` restarts cancel the old streams, and the stream buffer is `bufferingNewest(1)`.
- `swiftui-pro`: one fix, folded into Task 6 — the foreground refresh is a named method, not logic inline in
  `onChange`; arrows pass the view model's methods as actions. Subviews are structs (in the file, per
  `architecture.md`), rows are `Identifiable`.
