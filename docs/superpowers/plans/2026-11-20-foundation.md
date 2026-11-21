# Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everything the CleanLog screens stand on — test target, domain types and rules, month
statistics, the report text, formatters, repository protocols with fakes, and SwiftData persistence —
with no screen.

**Architecture:** Feature-first app target. `Models/` holds `Sendable` value types and pure rules;
`Formatting/` turns them into text; `Repositories/` declares protocols (plus in-memory fakes and a
stream helper); `Persistence/` is the only SwiftData code, mapping `@Model` records to domain values.
One contract test suite per repository runs against both the fake and the SwiftData implementation.

**Tech Stack:** Swift 6, SwiftUI (app shell only), SwiftData, Swift Testing, iOS 18.0, Xcode 26.1.

**Spec:** `docs/superpowers/specs/2026-11-20-foundation-design.md` (and the product spec
`docs/superpowers/specs/2026-11-13-cleanlog-design.md`). Rules: `CLAUDE.md`, `.claude/conventions/`.

## Global Constraints

- iOS 18.0 deployment target, iPhone only, Swift 6 language mode, default actor isolation `MainActor`.
- No third-party dependencies. No `import SwiftData` outside `Persistence/`, `App/`, `CleanLogTests/Persistence/`.
- `Models/`, `Repositories/`, `Persistence/`, `Formatting/` never import SwiftUI or UIKit.
- Money is `Money(minorUnits: Int)`; złoty only; display `"<number> zł"` with a no-break space (U+00A0).
- A calendar day is `DayKey`, never a midnight `Date`. No `Date()` and no `Calendar.current` inside
  `Models/` or `Formatting/` — `now`, `today` and calendars are parameters.
- Every Swift file passes `xcrun swift-format lint --strict` (the PostToolUse hook runs it).
- **Types in `Models/` and `Formatting/` are declared `nonisolated`** (plan review, swift-concurrency-pro):
  under default `MainActor` isolation a plain struct and its `Equatable`/`Hashable` conformances would
  be main-actor-bound, which pure values have no reason to be — and a future widget or `@concurrent`
  calculation could not use them. Repositories, records, `StoreObservers` and the app stay main-actor.
- Tests use `Calendar.warsaw` (Gregorian, `Europe/Warsaw`, `en_US_POSIX`) from `CleanLogTests/Support/`.
- Branch `feature/foundation`; one commit per task, imperative English subject, **no
  `Co-Authored-By` or any attribution line**. Push when a remote exists (none yet).
- Build: `xcodebuild -scheme CleanLog -destination 'generic/platform=iOS Simulator' build`.
  Test: `xcodebuild -scheme CleanLog -destination 'platform=iOS Simulator,name=iPhone 16' test`
  (append `-only-testing:CleanLogTests/<Suite>` to run one suite).

## Review Focus

1. An apartment name differing only by case or edge spaces (`"101 "` vs `"101"`) → rejected as a
   duplicate among active apartments, accepted when the other one is archived. (Task 3)
2. An access code of only spaces, or a negative price → code stored as `nil`; negative price
   rejected. (Task 3)
3. The timer left running past midnight and the app reopened next morning → the whole session counts
   on the day it started; that day's worked duration keeps growing until it is paused. (Task 5)
4. Ticking an apartment on a future day, or starting the timer on a past day → refused with a typed
   error, the stored day unchanged. (Tasks 4, 5, 10)
5. A report for a month whose input also contains days of the neighbouring months, days with only
   unticked entries, or a day with only separate apartments → neighbours and unticked-only days
   omitted, the separate-only day printed as `d.M-()=0+name`. (Task 7)

---

### Task 1: Test target, shared scheme, branch

**Files:**
- Modify: `CleanLog.xcodeproj/project.pbxproj`
- Create: `CleanLog.xcodeproj/xcshareddata/xcschemes/CleanLog.xcscheme`
- Create: `CleanLogTests/Support/Calendar+Warsaw.swift`
- Test: `CleanLogTests/SmokeTests.swift` (deleted in Task 2)

**Interfaces:**
- Produces: target `CleanLogTests` (`@testable import CleanLog` works); `extension Calendar { static let warsaw: Calendar }`;
  `extension Date { static func warsaw(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date }`.

- [ ] **Step 1:** `git switch -c feature/foundation`.
- [ ] **Step 2: Add the target to `project.pbxproj`.** A `PBXNativeTarget` `CleanLogTests`,
  `productType = "com.apple.product-type.bundle.unit-test"`, with a `PBXFileSystemSynchronizedRootGroup`
  for `CleanLogTests/` (same shape as the app's `CleanLog` group), Sources/Frameworks/Resources
  build phases, a `PBXTargetDependency` + `PBXContainerItemProxy` on `CleanLog`, and Debug/Release
  `XCBuildConfiguration`s with: `BUNDLE_LOADER = "$(TEST_HOST)"`,
  `TEST_HOST = "$(BUILT_PRODUCTS_DIR)/CleanLog.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/CleanLog"`,
  `PRODUCT_BUNDLE_IDENTIFIER` = the app's id with `Tests` appended (`-.CleanLogTests` until the real
  Bundle ID is chosen), `IPHONEOS_DEPLOYMENT_TARGET = 18.0`, `TARGETED_DEVICE_FAMILY = 1`,
  `SWIFT_VERSION = 6.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`,
  `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `GENERATE_INFOPLIST_FILE = YES`. Add it to the project's
  `targets` list.
- [ ] **Step 3: Shared scheme** `CleanLog.xcscheme`: build action with `CleanLog`, test action with
  the `CleanLogTests` testable, launch action on `CleanLog`.
- [ ] **Step 4: Support + smoke test.** `Calendar.warsaw` (Gregorian, `TimeZone(identifier: "Europe/Warsaw")`,
  `Locale(identifier: "en_US_POSIX")`), `Date.warsaw(...)` built through it, and
  `@Test func targetRuns() { #expect(Calendar.warsaw.timeZone.identifier == "Europe/Warsaw") }`.
- [ ] **Step 5: Run the test command.** Expected: `** TEST SUCCEEDED **`, 1 test passed. Also run the build command.
- [ ] **Step 6: Commit** `Add the CleanLogTests target and shared scheme`.

### Task 2: Money, DayKey, MonthKey

**Files:**
- Create: `CleanLog/Models/Money.swift`, `CleanLog/Models/DayKey.swift`, `CleanLog/Models/MonthKey.swift`
- Delete: `CleanLogTests/SmokeTests.swift`
- Test: `CleanLogTests/Models/MoneyTests.swift`, `CleanLogTests/Models/DayKeyTests.swift`, `CleanLogTests/Models/MonthKeyTests.swift`

**Interfaces:**
- Produces:
  - `struct Money: Sendable, Hashable, Comparable, Codable { let minorUnits: Int; init(minorUnits: Int); static let zero; static func + - ; static func += ; static func * (Money, Int) -> Money }`,
    `extension Sequence where Element == Money { func sum() -> Money }`
  - `struct DayKey: Sendable, Hashable, Comparable, Codable { let year, month, day: Int; init(year:month:day:); init(_ date: Date, calendar: Calendar); func startDate(in: Calendar) -> Date; func adding(days: Int, calendar: Calendar) -> DayKey; var monthKey: MonthKey; var storageValue: Int; init?(storageValue: Int) }`
  - `struct MonthKey: Sendable, Hashable, Comparable, Codable { let year, month: Int; init(year:month:); var previous: MonthKey; var next: MonthKey; func days(in: Calendar) -> [DayKey]; func contains(_: DayKey) -> Bool; var firstDayStorageValue: Int; var lastDayStorageValue: Int }`

- [ ] **Step 1: Failing tests.**
  - `Money`: `Money(minorUnits: 2800) * 6 + Money(minorUnits: 5600) == Money(minorUnits: 22400)`;
    `[Money(minorUnits: 2800), Money(minorUnits: 5600)].sum() == Money(minorUnits: 8400)`; `[Money]().sum() == .zero`;
    `Money(minorUnits: 100) < Money(minorUnits: 200)`.
  - `DayKey`: `DayKey(.warsaw(2026, 11, 13, 23, 59), calendar: .warsaw) == DayKey(year: 2026, month: 11, day: 13)`;
    across DST `DayKey(year: 2026, month: 3, day: 28).adding(days: 1, calendar: .warsaw) == DayKey(year: 2026, month: 3, day: 29)` and `+2 == 3/30`;
    across months `DayKey(year: 2026, month: 10, day: 31).adding(days: 1, …) == 11/1`, `adding(days: -1)` from 1/1/2027 is 12/31/2026;
    `storageValue == 20261113`, `DayKey(storageValue: 20261113) == key`, `DayKey(storageValue: 20261340) == nil`;
    ordering `11/9 < 11/13 < 12/1`.
  - `MonthKey`: `MonthKey(year: 2026, month: 1).previous == (2025, 12)`, `MonthKey(2026, 12).next == (2027, 1)`;
    `MonthKey(2026, 2).days(in: .warsaw).count == 28`, first `2/1`, last `2/28`;
    `contains(DayKey(2026, 2, 28))` true, `contains(DayKey(2026, 3, 1))` false;
    `firstDayStorageValue == 20260201`, `lastDayStorageValue == 20260231` (31 is a safe upper bound for range queries).
- [ ] **Step 2:** Run tests — FAIL (types missing).
- [ ] **Step 3: Implement** the three types. `startDate` uses `calendar.date(from:)` and
  `preconditionFailure("Invalid day \(self)")` when it returns `nil`. Comparison by `storageValue`
  (`year * 10000 + month * 100 + day`).
- [ ] **Step 4:** Run tests — PASS. Build passes.
- [ ] **Step 5: Commit** `Add Money, DayKey and MonthKey`.

### Task 3: Apartment and its validation

**Files:**
- Create: `CleanLog/Models/Apartment/Apartment.swift`, `CleanLog/Models/Apartment/ApartmentDraft.swift`
- Test: `CleanLogTests/Models/ApartmentDraftTests.swift`

**Interfaces:**
- Consumes: `Money`.
- Produces:
  - `struct Apartment: Sendable, Hashable, Identifiable { let id: UUID; var name: String; var price: Money; var accessCode: String?; var isReportedSeparately: Bool; var sortOrder: Int; var isArchived: Bool; let createdAt: Date }`
  - `struct ApartmentDraft: Sendable, Hashable { var name: String; var price: Money; var accessCode: String?; var isReportedSeparately: Bool; init(_ apartment: Apartment); init(name:price:accessCode:isReportedSeparately:); func validated(against existing: [Apartment], excluding id: UUID? = nil) throws(ApartmentError) -> ApartmentDraft }`
  - `enum ApartmentError: Error, Equatable { case emptyName, duplicateName, negativePrice, notFound }`

- [ ] **Step 1: Failing tests** (`existing` = active `"101"`, archived `"205"`):
  - `"  102 "` → returned draft name `"102"`; access code `"  4821 "` → `"4821"`; code `"   "` → `nil`; code `nil` → `nil`.
  - `""` and `"   "` → throws `.emptyName`.
  - `"101"`, `" 101 "`, and for a letter name `"6PIW"` against active `"6piw"` → throws `.duplicateName`.
  - `"205"` (archived) → accepted.
  - Editing `"101"` itself with `excluding: its id` → accepted.
  - `Money(minorUnits: -1)` → throws `.negativePrice`; `Money.zero` → accepted.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3: Implement.** Names compare with `trimmingCharacters(in: .whitespacesAndNewlines)`
  and `caseInsensitiveCompare == .orderedSame`; only non-archived apartments count.
- [ ] **Step 4:** Run — PASS.
- [ ] **Step 5: Commit** `Add Apartment and draft validation`.

### Task 4: WorkDay — entries, planning, cleaning, totals

**Files:**
- Create: `CleanLog/Models/WorkDay/WorkDay.swift`, `CleanLog/Models/WorkDay/DayEntry.swift`,
  `CleanLog/Models/WorkDay/WorkSession.swift`, `CleanLog/Models/WorkDay/WorkDay+Planning.swift`,
  `CleanLog/Models/WorkDay/WorkDayError.swift`
- Test: `CleanLogTests/Models/WorkDayPlanningTests.swift`, `CleanLogTests/Support/Fixtures.swift`

**Interfaces:**
- Consumes: `Money`, `DayKey`, `Apartment`.
- Produces:
  - `struct DayEntry: Sendable, Hashable, Identifiable { let id: UUID; let apartmentID: UUID; let name: String; let price: Money; let isReportedSeparately: Bool; let sortOrder: Int; var isCleaned: Bool; var cleanedAt: Date?; init(planning: Apartment) }` (+ memberwise for persistence)
  - `struct WorkSession: Sendable, Hashable, Identifiable { let id: UUID; let start: Date; var end: Date?; func duration(now: Date) -> Duration }`
  - `struct WorkDay: Sendable, Hashable, Identifiable { let id: UUID; let day: DayKey; var entries: [DayEntry]; var sessions: [WorkSession]; var manualDuration: Duration?; var isTimerFinished: Bool; static func empty(_ day: DayKey) -> WorkDay }`
  - `enum WorkDayError: Error, Equatable { case futureDay, notToday, timerState, entryNotFound }`
  - On `WorkDay`: `func planning(_ apartments: [Apartment]) -> WorkDay`, `func removingEntry(_ id: UUID) -> WorkDay`,
    `func copyingPlan(from other: WorkDay) -> WorkDay`,
    `func settingCleaned(_ entryID: UUID, to isCleaned: Bool, now: Date, today: DayKey) throws(WorkDayError) -> WorkDay`,
    `var earned: Money`, `var planned: Money`, `var cleanedCount: Int`, `var hasCleanedEntries: Bool`
  - Fixtures: `Apartment.fixture(_ name: String, minorUnits: Int = 2800, separate: Bool = false, sortOrder: Int = 0, archived: Bool = false)`

- [ ] **Step 1: Failing tests.**
  - Planning `[100, 101]` then `[101, 102]` → entries `100, 101, 102` (no duplicate `101`); each entry's
    snapshot equals the apartment's name, price, flag and sortOrder; all unticked.
  - Snapshot survives: plan `100` at 28 zł, then a changed `Apartment` (price 30 zł) is not re-applied — the entry keeps 28 zł.
  - `copyingPlan(from:)` a day with `100` (ticked) and an archived `205` → target has both, unticked, same snapshots, new entry ids; copying onto a day that already has `100` adds only `205`.
  - `removingEntry` removes exactly that entry; unknown id → unchanged.
  - `settingCleaned(id, to: true, now: 13.11 10:00, today: 13.11)` → `isCleaned`, `cleanedAt == now`; `false` → `cleanedAt == nil`;
    on a day `14.11` with today `13.11` → throws `.futureDay`; past day `12.11` → allowed; unknown id → `.entryNotFound`.
  - Totals for `100` (28, ticked), `101` (28), `106` (56, ticked): `earned == 8400`, `planned == 11200`, `cleanedCount == 2`, `hasCleanedEntries`.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3: Implement.** Rules are `func`s returning a modified copy; nothing mutates in place from outside.
- [ ] **Step 4:** Run — PASS.
- [ ] **Step 5: Commit** `Add WorkDay planning and cleaning rules`.

### Task 5: WorkDay — timer and worked time

**Files:**
- Create: `CleanLog/Models/WorkDay/WorkDay+Timer.swift`
- Test: `CleanLogTests/Models/WorkDayTimerTests.swift`

**Interfaces:**
- Consumes: Task 4 types.
- Produces: `enum TimerState: Sendable, Equatable { case idle, running(since: Date), paused, finished }`;
  on `WorkDay`: `var timerState: TimerState`,
  `func startingTimer(at now: Date, today: DayKey) throws(WorkDayError) -> WorkDay`,
  `func pausingTimer(at now: Date, today: DayKey) throws(WorkDayError) -> WorkDay`,
  `func finishingTimer(at now: Date, today: DayKey) throws(WorkDayError) -> WorkDay`,
  `func workedDuration(now: Date) -> Duration`, `func settingManualDuration(_: Duration?) -> WorkDay`,
  `var hasRecordedTime: Bool` (a session exists or `manualDuration != nil`).

- [ ] **Step 1: Failing tests** (day and today `13.11`):
  - Transitions: idle → start 07:30 → `.running(since: 07:30)`; pause 10:00 → `.paused`; start 10:25 →
    running; finish 13:05 → `.finished`; start again 14:00 → running, `isTimerFinished == false`.
  - Refused (`.timerState`): pause from idle, pause from paused, finish from idle, start from running.
  - `.notToday`: start on `12.11` and on `14.11` with today `13.11`; the returned error leaves the day unchanged.
  - `workedDuration`: sessions 07:30–10:00 and 10:25–13:05 → `.seconds(5 * 3600 + 10 * 60)` (5:10);
    open session from 10:25 with `now` 11:25 → 2:30 + 1:00 = `.seconds(3 * 3600 + 30 * 60)`;
    session 23:00 on 13.11 → 01:00 on 14.11 → `.seconds(2 * 3600)` on the 13th's day;
    `settingManualDuration(.seconds(4 * 3600))` overrides the sum; `nil` restores it.
  - `hasRecordedTime` false for an empty day, true with a session or a manual duration.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3: Implement.** The state is derived: an open session → running; none and
  `isTimerFinished` → finished; sessions, none open → paused; no sessions → idle (`isTimerFinished`
  without sessions also reads idle).
- [ ] **Step 4:** Run — PASS.
- [ ] **Step 5: Commit** `Add the work timer rules`.

### Task 6: MonthStats

**Files:**
- Create: `CleanLog/Models/MonthStats.swift`
- Test: `CleanLogTests/Models/MonthStatsTests.swift`

**Interfaces:**
- Consumes: `WorkDay`, `Money`.
- Produces: `struct ApartmentCount: Sendable, Hashable { let apartmentID: UUID; let name: String; let count: Int }`;
  `struct MonthStats: Sendable, Equatable { let earned: Money; let cleanedCount: Int; let workingDays: Int; let workedDuration: Duration; let earningsPerHour: Money?; let averagePerWorkingDay: Money?; let topApartments: [ApartmentCount]; static func calculate(days: [WorkDay], now: Date) -> MonthStats }`

- [ ] **Step 1: Failing tests.**
  - Empty input → earned `.zero`, counts 0, `workedDuration == .zero`, both optionals `nil`, `topApartments == []`.
  - Three days: A (100, 101 ticked, 106 ticked, sessions 2 h), B (100 ticked, no time), C (only 102 unticked, manual 1 h):
    `earned == 11200` (28+56 + 28), `cleanedCount == 3`, `workingDays == 2` (C has nothing ticked),
    `workedDuration == 3 h`, `earningsPerHour == Money(minorUnits: 2800)` (days with recorded time are A and C:
    8400 earned over 3 h; B's 2800 has no hours and is left out), `averagePerWorkingDay == Money(minorUnits: 5600)`.
  - Rounding half-up: earned 1000 minor units over 3 h → `Money(minorUnits: 333)`; 1001 over 2 h (half) → `501`.
  - `topApartments`: `100` ticked on 3 days, `101` on 2, `102` on 2, `103` on 1 → `[100 (3), 101 (2), 102 (2)]`
    (ties by name); the name is the snapshot from the latest day.
  - A day with a manual duration of zero contributes no hours and no division by zero.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3: Implement.** Integer half-up division:
  `(numerator * 2 + denominator) / (denominator * 2)`; per hour uses seconds:
  `earnedMinorUnits * 3600` over `totalSeconds`.
- [ ] **Step 4:** Run — PASS.
- [ ] **Step 5: Commit** `Add month statistics`.

### Task 7: ReportBuilder

**Files:**
- Create: `CleanLog/Formatting/ReportBuilder.swift`
- Test: `CleanLogTests/Formatting/ReportBuilderTests.swift`, `CleanLogTests/Formatting/OctoberReport.swift`

**Interfaces:**
- Consumes: `WorkDay`, `MonthKey`, `DayKey`.
- Produces: `enum ReportBuilder { static func report(for month: MonthKey, days: [WorkDay]) -> String }`

- [ ] **Step 1: The October fixture.** `OctoberReport.expected` is this exact text (the user's real report,
  typos corrected; template order `54, 64, 96, 100, 105, 115, 116, 138, 6piw, 133kol`, `155` separate):

```
1.10-(54,96,100,105,115,116,138)=7
2.10-(54,64,96,105,115,138,6piw)=7+155
3.10-(54,64,96,100,105,115,116)=7+155
4.10-(54,64,96,100,105,115,116,138)=8+155

5.10-(54,96,100,105,115,138,6piw)=7
6.10-(54,96,105,115,116,138)=6
7.10-(54,100,115,116)=4+155
8.10-(54,64,96,100,105,115,116,138)=8+155
9.10-(64,96,100,105,115,138)=6
10.10-(54,64,96,115,116,138)=6+155
11.10-(54,64,96,100,105,115,116,138)=8+155

12.10-(96,100,115,138,133kol)=5
13.10-(100,105,115,116)=4
14.10-(96,116)=2
15.10-(96,100,105,115,138)=5
16.10-(54,64,105,133kol)=4+155
17.10-(100,105,115,116,138)=5
18.10-(54,64,96,100,105,115,138)=7+155

19.10-(54,96,100,105,116,138)=6
20.10-(54,100,105,115,116,138)=6+155
21.10-(54,64,96,100,105,115,116,138)=8+155
22.10-(64,100,105,115,116,138)=6
23.10-(64,96,116,138)=4+155
24.10-(54,105,115,116,138)=5
25.10-(54,96,100,105,115,138)=6+155

26.10-(64,115,138)=3+155
27.10-(54,64,96,105,115,133kol)=6
28.10-(54,96,100,115,116,138)=6
29.10-(54,64,96,100,138)=5
30.10-(96,115,116,133kol)=4+155
31.10-(96,100,115)=3+155
```

  `OctoberReport.days` builds the `[WorkDay]` from a table of `(day, [names])` per line (separate
  flag and sortOrder from the template above), with each day's entries **shuffled** and one extra
  **unticked** apartment per day, so the builder must sort and filter.
- [ ] **Step 2: Failing tests.**
  - `report(for: October 2026, days: OctoberReport.days) == OctoberReport.expected`.
  - Neighbours ignored: adding 30.09 and 1.11 days with ticked entries changes nothing.
  - A day with only unticked entries is omitted; a month with none ticked → `""`.
  - Only a separate apartment ticked on 5.11 → `"5.11-()=0+155"`; two separates in sortOrder → `"…=3+155+160"`.
  - Weeks start Monday whatever the input order of days: November 2026 days 1 (Sun) and 2 (Mon) → a blank line between them.
- [ ] **Step 3:** Run — FAIL.
- [ ] **Step 4: Implement.** Its own `Calendar(identifier: .gregorian)` with `firstWeekday = 2` and
  `TimeZone(identifier: "UTC")` used only to find weeks of `DayKey`s (`startDate(in:)` +
  `component(.weekOfYear)` together with `.yearForWeekOfYear`); entries sorted by
  `(sortOrder, name)`; lines joined with `"\n"`, weeks with `"\n\n"`, no trailing newline.
- [ ] **Step 5:** Run — PASS.
- [ ] **Step 6: Commit** `Add the report builder`.

### Task 8: MoneyFormat and DurationFormat

**Files:**
- Create: `CleanLog/Formatting/MoneyFormat.swift`, `CleanLog/Formatting/DurationFormat.swift`
- Test: `CleanLogTests/Formatting/MoneyFormatTests.swift`, `CleanLogTests/Formatting/DurationFormatTests.swift`

**Interfaces:**
- Produces: `enum MoneyFormat { static func string(_ money: Money, locale: Locale = .current) -> String }`;
  `enum DurationFormat { static func clock(_ duration: Duration) -> String; static func short(_ duration: Duration) -> String }`

- [ ] **Step 1: Failing tests** (`\u{00A0}` = no-break space):
  - `uk_UA`: 201600 → `"2\u{00A0}016\u{00A0}zł"`, 2850 → `"28,50\u{00A0}zł"`, 2800 → `"28\u{00A0}zł"`, 0 → `"0\u{00A0}zł"`.
  - `en_US`: 201600 → `"2,016\u{00A0}zł"`, 2850 → `"28.50\u{00A0}zł"`.
  - `pl_PL`: 201600 → `"2016\u{00A0}zł"` (Polish does not group four digits), 1234500 → `"12\u{00A0}345\u{00A0}zł"`.
  - `clock(.seconds(4 * 3600 + 12 * 60 + 35)) == "4:12:35"`, `clock(.zero) == "0:00:00"`, `clock(.seconds(-5)) == "0:00:00"`.
  - `short(.seconds(5 * 3600 + 10 * 60)) == "5:10"`, `short(.seconds(59)) == "0:00"`, `short(.seconds(62 * 3600)) == "62:00"`.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3: Implement.** Money: `Decimal(minorUnits) / 100` with
  `.number.precision(.fractionLength(whole ? 0 : 2)).locale(locale)`, then `"\u{00A0}zł"`; replace any
  ordinary space the locale produces with U+00A0. Durations: whole seconds, negatives clamp to 0,
  `String(format:)` with `en_US_POSIX`.
- [ ] **Step 4:** Run — PASS. If a CLDR separator differs on the installed runtime (e.g. U+202F), fix the
  test expectation to the runtime's character and note it in the commit body — the rule is "the locale's grouping".
- [ ] **Step 5: Commit** `Add money and duration formatters`.

### Task 9: Repository protocols, stream helper, fakes, contract suites

**Files:**
- Create: `CleanLog/Repositories/ApartmentRepository.swift`, `CleanLog/Repositories/WorkDayRepository.swift`,
  `CleanLog/Repositories/StoreObservers.swift`, `CleanLog/Repositories/FakeApartmentRepository.swift`,
  `CleanLog/Repositories/FakeWorkDayRepository.swift`
- Test: `CleanLogTests/Repositories/ApartmentRepositoryContractTests.swift`,
  `CleanLogTests/Repositories/WorkDayRepositoryContractTests.swift`, `CleanLogTests/Support/Repositories+UnderTest.swift`

**Interfaces:**
- Consumes: domain types, `ApartmentDraft.validated`.
- Produces:
  - `protocol ApartmentRepository: AnyObject { func apartments(includingArchived: Bool) -> AsyncStream<[Apartment]>; func add(_ draft: ApartmentDraft) async throws -> Apartment; func update(_ apartment: Apartment) async throws; func archive(_ id: UUID) async throws; func reorder(_ ids: [UUID]) async throws }`
  - `protocol WorkDayRepository: AnyObject { func day(_ day: DayKey) -> AsyncStream<WorkDay>; func days(in month: MonthKey) -> AsyncStream<[WorkDay]>; func latestDayWithEntries(before day: DayKey) async throws -> WorkDay?; func update(_ day: DayKey, _ change: (WorkDay) throws -> WorkDay) async throws }`
  - `final class StoreObservers { func stream<Value: Sendable>(_ read: @escaping () -> Value) -> AsyncStream<Value>; func notify() }`
    — one per repository, generic per stream, so a work-day save notifies the day and the month streams with one `notify()`.
  - Domain helpers shared by the fake and the SwiftData repositories: `Apartment(_ draft:sortOrder:createdAt:)`,
    `Apartment.applying(_ draft:)` (editable fields only), `WorkDay.isBlank` (no entries, no recorded time, not finished).
  - `final class FakeApartmentRepository: ApartmentRepository { init(_ apartments: [Apartment] = [], now: @escaping () -> Date = Date.init) }`,
    `final class FakeWorkDayRepository: WorkDayRepository { init(_ days: [WorkDay] = []) }` — both `#if DEBUG`.
  - Tests: `enum RepositoryKind: CaseIterable { case fake }` (Task 10 adds `.swiftData`) with
    `func makeApartments(now:) -> any ApartmentRepository` and `func makeWorkDays() -> any WorkDayRepository`.

- [ ] **Step 1: Failing contract tests**, each `@Test(arguments: RepositoryKind.allCases)`:
  - Apartments: stream yields `[]` first; `add` 3 drafts → stream yields them by `sortOrder` 0,1,2 with
    `createdAt == now`, trimmed names, `nil` blank code; duplicate add throws `ApartmentError.duplicateName`;
    `update` renames and re-validates (`.duplicateName` against another, own name OK), unknown id → `.notFound`;
    `archive` hides from `includingArchived: false`, keeps it in `true`; `reorder([c, a, b])` → order c, a, b.
  - Work days: `day(13.11)` first yields `.empty(13.11)` with no entries; `update(13.11) { $0.planning([a]) }` →
    the stream yields the planned day; `update` whose change throws → error rethrown, the stream yields
    nothing new, a later read is unchanged; `days(in: November)` returns only November days, ascending;
    with 12.11 stored but emptied, 11.11 and 10.11 with entries, `latestDayWithEntries(before: 13.11)` is
    the 11.11 day; with no earlier entries it is `nil`.
  - Streams: two observers of the same day both receive the update; a cancelled consumer task does not crash later writes.
    Read with `var iterator = stream.makeAsyncIterator()`: take the initial value **before** writing —
    with `.bufferingNewest(1)` a write before the first read replaces the initial value, by design.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3: Implement** protocols (`@MainActor` by default isolation), `StoreObservers` (continuations
  keyed by `UUID`, each stream from `AsyncStream.makeStream(of:bufferingPolicy: .bufferingNewest(1))` —
  every value is the full current state, so a slow consumer needs only the latest; `stream` yields `read()` immediately; `onTermination` hops with
  `Task { @MainActor in self?.remove(id) }`; `notify()` yields `read()` to each), and the fakes
  (`[UUID: Apartment]`, `[DayKey: WorkDay]`; same validation via `ApartmentDraft.validated`; a day is
  stored on `update` when the result has entries or sessions or it was already stored).
- [ ] **Step 4:** Run — PASS.
- [ ] **Step 5: Commit** `Add repository protocols, fakes and contract tests`.

### Task 10: SwiftData persistence

**Files:**
- Create: `CleanLog/Persistence/SchemaV1.swift` (records nested in `SchemaV1`, top-level typealiases),
  `CleanLog/Persistence/CleanLogMigrationPlan.swift`, `CleanLog/Persistence/ModelContainerFactory.swift`,
  `CleanLog/Persistence/ApartmentRecord+Domain.swift`, `CleanLog/Persistence/WorkDayRecord+Domain.swift`,
  `CleanLog/Persistence/SwiftDataApartmentRepository.swift`, `CleanLog/Persistence/SwiftDataWorkDayRepository.swift`
- Modify: `CleanLogTests/Support/Repositories+UnderTest.swift` (add `.swiftData`)
- Test: `CleanLogTests/Persistence/WorkDayRecordMappingTests.swift`

**Interfaces:**
- Consumes: Task 9 protocols and `StoreObservers`, domain types, `Apartment(_:sortOrder:createdAt:)`,
  `Apartment.applying(_:)` and `WorkDay.isBlank` (store a day only when it was stored or is not blank — as the fake).
- Produces: `enum ModelContainerFactory { static func make(inMemory: Bool) throws -> ModelContainer }`;
  `final class SwiftDataApartmentRepository: ApartmentRepository { init(container: ModelContainer, now: @escaping () -> Date = Date.init) }`;
  `final class SwiftDataWorkDayRepository: WorkDayRepository { init(container: ModelContainer) }` — they own the
  container (a `ModelContext` does not keep it alive) and work on its `mainContext`.
  Child records carry `position` so entry and session order survives the unordered to-many relationship.
  Records: `ApartmentRecord` (`id: UUID`, `name: String`, `priceMinorUnits: Int`, `accessCode: String?`,
  `isReportedSeparately`, `sortOrder`, `isArchived`, `createdAt`), `WorkDayRecord` (`id`, `dayValue: Int`,
  `manualDurationSeconds: Int?`, `isTimerFinished`, `entries: [DayEntryRecord]?`, `sessions: [WorkSessionRecord]?`,
  both `.cascade` with inverses), `DayEntryRecord` (snapshot fields, `isCleaned`, `cleanedAt`, `day: WorkDayRecord?`),
  `WorkSessionRecord` (`id`, `start`, `end`, `day`). Every stored property has a default; no `.unique`.

- [ ] **Step 1: Failing tests.** `RepositoryKind.swiftData` (in-memory container kept alive by the
  repository-under-test wrapper) — the Task 9 suites now run twice. Mapping tests: a `WorkDay` with
  2 entries (one ticked with `cleanedAt`), 2 sessions (one open), manual 4 h, finished flag → `apply` then
  `domain` round-trips equal; applying a version with one entry removed, one changed and one added
  leaves exactly those entry records (count the `DayEntryRecord`s in the context); `update` twice on the
  same `DayKey` leaves one `WorkDayRecord` with that `dayValue`; a change producing an empty day with no
  record creates none.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3: Implement.** First check how `@Model` records behave under default `MainActor`
  isolation: if `#Predicate` or the macro expansion reports isolation errors, declare the record classes
  `nonisolated` (they are confined to the main `ModelContext` either way; never `@unchecked Sendable`).
  `SchemaV1.versionIdentifier = Schema.Version(1, 0, 0)`; migration plan with
  `[SchemaV1.self]` and no stages; factory builds `Schema(versionedSchema: SchemaV1.self)` with the plan and
  `ModelConfiguration(isStoredInMemoryOnly:)`. Repositories fetch with `#Predicate` on `id`/`dayValue`
  (`dayValue` between `month.firstDayStorageValue` and `lastDayStorageValue` for a month), map through
  `domain`/`apply`, `try context.save()`, then `observers.notify()`. Apartment rules go through
  `ApartmentDraft.validated` exactly as in the fake.
- [ ] **Step 4:** Run — all suites PASS for both kinds.
- [ ] **Step 5: Commit** `Add SwiftData persistence`.

### Task 11: App wiring, convention updates, full verification

**Files:**
- Create: `CleanLog/App/AppDependencies.swift`
- Move: `CleanLog/CleanLogApp.swift` → `CleanLog/App/CleanLogApp.swift` (modify), `CleanLog/ContentView.swift` → `CleanLog/App/ContentView.swift`
- Move: `CleanLog/Assets.xcassets` → `CleanLog/Resources/Assets.xcassets`
- Modify: `.claude/conventions/architecture.md`, `docs/superpowers/specs/2026-11-13-cleanlog-design.md`
- Test: `CleanLogTests/App/AppDependenciesTests.swift`

**Interfaces:**
- Produces: `@Observable final class AppDependencies { let apartments: any ApartmentRepository; let workDays: any WorkDayRepository; static func live() throws -> AppDependencies; static func preview() -> AppDependencies /* #if DEBUG */ }`

- [ ] **Step 1: Failing test:** `AppDependencies.preview()` exposes fakes whose streams yield `[]` and `.empty(day)`.
- [ ] **Step 2:** Run — FAIL.
- [ ] **Step 3: Implement.** `live()` keeps the `ModelContainer` in a private property and builds both
  SwiftData repositories on `container.mainContext`. `CleanLogApp` holds
  `@State private var dependencies: AppDependencies` initialised from `live()` with
  `preconditionFailure("Could not open the store: \(error)")` on failure, and injects it with
  `.environment(dependencies)` on `ContentView`. Move the files (the synchronized group picks the
  new folders up; check the asset catalog still compiles).
- [ ] **Step 4: Docs.** In `architecture.md`: replace "converts to and from `Date` only in
  `Formatting/` and `Persistence/`" with "converts only through `DayKey(_:calendar:)` and
  `startDate(in:)`, always with an explicit calendar"; replace the "Writes are `async throws` and say what
  they do" bullet with the single `update(_:_:)` write path for days (rules live on `WorkDay`); move
  `StoreObservers` to `Repositories/` in the folder table. In the product spec's report section:
  "Weeks always start on Monday (the boss's fixed format), whatever the device locale."
- [ ] **Step 5: Verify:** test command → `** TEST SUCCEEDED **`; build command → `** BUILD SUCCEEDED **`;
  `xcrun swift-format lint --strict --recursive CleanLog CleanLogTests` → no output; launch on the iPhone 16
  simulator once and confirm the template screen appears (the store opens).
- [ ] **Step 6: Commit** `Wire app dependencies and update conventions`.

---

## After the plan (the feature workflow, `CLAUDE.md`)

1. Code review on the branch diff: `swift-concurrency-pro` (streams, `StoreObservers`, `onTermination`,
   isolation of `@Model` under Swift 6) and `swiftui-pro` (the app shell), then the SOLID / clean-code
   pass. Fix, re-run build, tests, lint.
2. Merge `feature/foundation` into `main`, delete this plan and the foundation design file, create
   `docs/plan.md` with the done/next checklist, commit, push when a remote exists, and give the PR description.
