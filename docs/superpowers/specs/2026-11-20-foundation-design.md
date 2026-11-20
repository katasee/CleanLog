# Foundation — design

Date: 2026-11-20. Feature spec (delete after merge). Product spec:
`docs/superpowers/specs/2026-11-13-cleanlog-design.md`. Rules: `.claude/conventions/`.

## Intent

Build everything the screens will stand on, and no screen: the test target, the domain types and
their rules, the pure calculations, the report text, and persistence behind repository protocols.
Every later screen plan should only bind a view model to tested logic, never compute anything new.

## Goals

- Every rule from the product spec that is not layout lives in tested code: money sums, the timer,
  planning, "as yesterday", the future-day lock, month statistics, the report format.
- The October report from the product spec is reproduced byte for byte by a test.
- SwiftData is reachable only through repository protocols; previews and view-model tests run on
  in-memory fakes.
- Build, tests and `swift-format lint --strict` are green.

## Non-goals

- Any SwiftUI screen, view model, design token or string-catalog key (those come with the screens).
- Display date formatting (weekday names, "12 листопада") — the first screen that shows a date adds it.
- Reminders, settings storage, WhatsApp sending, Live Activity, iCloud sync.
- Seed or demo data in the shipping app.

## Anti-goals

- Business rules inside repositories or SwiftData records — persistence stores, the domain decides.
- A test that passes only in one time zone or locale.
- A record schema that would need a migration to turn on CloudKit.

## Approaches

| | Approach | Trade-off |
|---|---|---|
| **A (chosen)** | Folders in the app target (`Models/`, `Formatting/`, `Repositories/`, `Persistence/`) + a hosted `CleanLogTests` target | simplest; matches the conventions; tests run on the simulator (~20–40 s); layer boundaries held by the hook and review |
| B | Local Swift package `CleanLogKit` (`Domain`, `Persistence`) + `swift test` | compiler-enforced boundaries, tests in seconds without a simulator; `public` on everything the app uses, conventions and hook to rewrite |

The user picked A: the app is small, and `public` everywhere to enforce boundaries the hook already
checks is not worth it. Moving the domain to a package stays easy if a widget or Live Activity
target ever needs it.

## Project setup

- Add a **`CleanLogTests`** unit-test target (Swift Testing), hosted by the app
  (`TEST_HOST`/`BUNDLE_LOADER`), with its own synchronized folder `CleanLogTests/`, added to the
  `CleanLog` scheme's test action. Same build settings as the app: iOS 18.0, iPhone, Swift 6,
  `MainActor` default isolation.
- The app keeps launching on the template `ContentView` until the Today UI replaces it.
  `CleanLogApp` builds `AppDependencies` and puts it in the environment.

## Domain (`Models/`)

All `struct`/`enum`, `Sendable`, `Equatable`, Foundation only.

- **`Money`** — `grosze: Int`; `static let zero`; `+`, `-`, `+=`, `Money * Int`; `Comparable`.
  `Sequence<Money>.sum()`.
- **`DayKey`** — `year`, `month`, `day`; `Comparable`, `Hashable`, `Codable`;
  `init(_ date: Date, calendar: Calendar)`, `func startDate(in calendar: Calendar) -> Date`,
  `func adding(days: Int, calendar: Calendar) -> DayKey`, `var month: MonthKey`;
  `var storageValue: Int` (`yyyymmdd`) and `init?(storageValue:)` for persistence.
- **`MonthKey`** — `year`, `month`; `Comparable`, `Hashable`; `previous`, `next`,
  `func days(in calendar: Calendar) -> [DayKey]`, `contains(_ day: DayKey)`.
- **`Apartment`** — `id: UUID`, `name`, `price: Money`, `accessCode: String?`,
  `isReportedSeparately`, `sortOrder`, `isArchived`, `createdAt`. The access code is the door or
  key-box code shown on the Today rows; it is permanent per apartment, free text (`1234#`), trimmed,
  and an empty string is stored as `nil`.
- **The access code is not snapshotted into `DayEntry`.** It is a fact about the apartment now, not
  about the day: a code changed in the template must show on today's rows at once. The Today view
  model looks it up by `apartmentID` from the apartments stream; an archived apartment's code is
  still found (the fetch includes archived ones for that lookup).
- **`DayEntry`** — `id`, `apartmentID: UUID`, snapshots `name`, `price`, `isReportedSeparately`,
  `sortOrder`; `isCleaned`, `cleanedAt: Date?`. `init(planning apartment: Apartment)` takes the
  snapshot.
- **`WorkSession`** — `id`, `start: Date`, `end: Date?`; `func duration(now: Date) -> Duration`.
- **`WorkDay`** — `id`, `day: DayKey`, `entries: [DayEntry]`, `sessions: [WorkSession]`,
  `manualDuration: Duration?`, `isTimerFinished: Bool`. `static func empty(_ day: DayKey)`.

### Rules on `WorkDay` (pure, value-returning, `throws` where a rule can refuse)

- **Planning**: `planning(_ apartments: [Apartment]) -> WorkDay` appends an entry per apartment not
  already on the day (by `apartmentID`); `removingEntry(_ id:)`; `copyingPlan(from other: WorkDay)`
  plans the other day's apartments, unticked, from *their snapshots* (an apartment archived since
  is still copied — it was really on that day).
- **Cleaning**: `settingCleaned(_ entryID:, _ isCleaned:, now:, today: DayKey) throws` — sets
  `cleanedAt` to `now` or `nil`; throws `WorkDayError.futureDay` when `day > today`.
- **Timer** — state derived, never stored as a flag besides `isTimerFinished`:
  - `timerState(now:) -> TimerState` = `.idle` (no sessions) · `.running(since:)` (an open session)
    · `.paused` (sessions, none open, not finished) · `.finished`.
  - `startingTimer(at:)` (from idle, paused or finished: opens a session, clears
    `isTimerFinished`), `pausingTimer(at:)` (closes the open session), `finishingTimer(at:)`
    (closes it if open, sets `isTimerFinished`). Each throws `WorkDayError.timerState` from a state
    where it makes no sense, and `.notToday` unless `day == today` — a past day's time is corrected
    only through the manual duration, a future day has none. *(builder's call)*
  - `workedDuration(now:) -> Duration` = `manualDuration` if set, else the sum of sessions (an open
    one counts up to `now`). A session crossing midnight stays on the day it started.
  - `settingManualDuration(_ duration: Duration?)` — `nil` returns to the measured sum.
- **Totals**: `earned` (sum of cleaned prices), `planned` (sum of all), `cleanedCount`,
  `hasCleanedEntries`.

### Month statistics

`MonthStats.calculate(days: [WorkDay], now: Date) -> MonthStats`, numbers only:
`earned: Money`, `cleanedCount: Int` (all cleaned, separate ones included), `workingDays: Int`
(days with a cleaned entry), `workedDuration: Duration`, `earningsPerHour: Money?` (earned on days
with recorded time ÷ their hours, rounded half-up to whole grosze; `nil` without recorded time),
`averagePerWorkingDay: Money?` (`nil` without working days), `topApartments: [ApartmentCount]`
(grouped by `apartmentID`, latest snapshot name, sorted by count then name, top 3). The previous
month's comparison is the caller running `calculate` twice — the percentage is presentation.

## Formatting (`Formatting/`)

- **`ReportBuilder.report(for month: MonthKey, days: [WorkDay]) -> String`** — the format in the
  product spec. Lines for days of `month` with cleaned entries, ascending; inside the brackets
  cleaned non-separate entries by snapshot `sortOrder`, then name; `={count}`; then `+{name}` per
  cleaned separate entry in the same order; a day with only separate entries is `{d}.{M}-()=0+…`.
  **Weeks always start on Monday** — this is the boss's fixed format, not the device locale (the
  product spec said "locale"; this design corrects it, and the calendar grid keeps the locale). One
  blank line between weeks, none at the start or end, no trailing newline. Uses a Gregorian
  calendar it builds itself, never `Calendar.current`.
- **`MoneyFormat.string(_ money: Money) -> String`** — the number with `Locale.current` grouping and
  decimal separator, no fraction digits when whole, then ` zł` (`2 016 zł`, `28,50 zł`). Not
  `.currency(code: "PLN")`, which prints "PLN 28.00" on an English device. *(builder's call)*
- **`DurationFormat.clock(_:) -> String`** (`4:12:35`) and **`DurationFormat.short(_:)`** (`5:10`,
  hours and minutes) — locale-independent digits.

## Repositories (`Repositories/`)

Protocols speak domain types only; `@MainActor`.

```swift
protocol ApartmentRepository {
    func apartments(includingArchived: Bool) -> AsyncStream<[Apartment]>  // by sortOrder
    func add(_ draft: ApartmentDraft) async throws -> Apartment
    func update(_ apartment: Apartment) async throws
    func archive(_ id: UUID) async throws
    func reorder(_ ids: [UUID]) async throws
}

protocol WorkDayRepository {
    func day(_ day: DayKey) -> AsyncStream<WorkDay>         // `.empty(day)` until first write
    func days(in month: MonthKey) -> AsyncStream<[WorkDay]>
    func latestDayWithEntries(before day: DayKey) async throws -> WorkDay?
    func update(_ day: DayKey, _ change: (WorkDay) throws -> WorkDay) async throws
}
```

- **One write path for days: `update(_:_:)`** loads the day (or `.empty`), applies a domain rule,
  saves the result. View models call
  `repository.update(day) { try $0.settingCleaned(id, true, now: now, today: today) }` — every
  rule stays in `WorkDay`, the repository never grows a method per action.
- `ApartmentDraft` — `name`, `price`, `accessCode`, `isReportedSeparately`: what the form edits,
  validated by `ApartmentDraft.validated(against existing: [Apartment]) throws` in `Models/`, so the
  rule is shared by the repository, the fake and the form's view model.
- `ApartmentRepository.add`/`update` throw `ApartmentError.duplicateName` (case- and
  edge-whitespace-insensitive among active apartments) and `.emptyName`; a name is trimmed before
  it is stored.
- Streams yield the current value at once, then again after every save that can change it.
- `FakeApartmentRepository` and `FakeWorkDayRepository` (`#if DEBUG`) keep state in memory, apply
  the same rules and yield to observers — used by previews and view-model tests.

## Persistence (`Persistence/`)

- **`SchemaV1: VersionedSchema`** with `ApartmentRecord`, `WorkDayRecord`, `DayEntryRecord`,
  `WorkSessionRecord`, and an empty `CleanLogMigrationPlan` — versioned from day one, so the first
  real change is a migration stage, not a rescue.
- Records are CloudKit-compatible: every attribute has a default, relationships optional with
  `.cascade` from day to entries and sessions, no `@Attribute(.unique)`. Stored forms: `Money` →
  `pricesGrosze: Int`, `DayKey` → `dayValue: Int`, `Duration?` → `manualDurationSeconds: Int?`.
- `Record+Domain.swift` per record: `var domain: …` and `func apply(_ domain: …)`, which syncs
  child records by `id` (insert new, update existing, delete removed).
- **`SwiftDataApartmentRepository`**, **`SwiftDataWorkDayRepository`** take a `ModelContext`.
  `update` fetches by `dayValue`, creating the record only when the change produces a non-empty
  day; one `WorkDayRecord` per `dayValue` is guaranteed by that fetch-or-create. A day emptied later
  keeps its (empty) record. Save, then notify.
- `reorder(_:)` takes the full list of active ids and rewrites `sortOrder` as their positions.
- **`StoreObservers<Value>`** — a small helper holding `AsyncStream` continuations by id; each
  repository re-queries and yields after its saves; `onTermination` removes the observer.
- **`ModelContainerFactory.make(inMemory: Bool) throws -> ModelContainer`**, used by
  `AppDependencies` (on disk) and tests (in memory).

## App (`App/`)

- **`AppDependencies`** — `@Observable @MainActor final class` holding `apartments` and
  `workDays` as protocol types, `static func live() throws` and (`#if DEBUG`) `static func preview()`
  with fakes. A store that fails to open is shown as a fatal-error screen later; for now `live()`
  failing is a `preconditionFailure` with the error.
- `CleanLogApp` creates it once and injects it with `.environment(_:)`.

## Tests (`CleanLogTests/`, Swift Testing)

Pinned `Calendar` (Gregorian, `Europe/Warsaw`), fixed dates, no `Date()`.

- `Models/`: `Money` arithmetic; `DayKey`/`MonthKey` conversion across a DST change and across
  months; planning de-duplication; copy-plan from snapshots; the future-day lock; every timer
  transition and refused transition; worked duration with pauses, an open session, midnight and a
  manual override; `MonthStats` including `nil` cases and rounding.
- `Formatting/`: the October report byte for byte (`6piw`, `133kol`, `+155`, the week break after
  Sunday 4th); a day with only separate entries; an empty month is `""`; `MoneyFormat` and
  `DurationFormat` with a pinned locale.
- `Persistence/`: each SwiftData repository on an in-memory container — round trip of every field,
  child sync on update, one record per day, stream emissions after writes, duplicate-name errors,
  archive keeps history.
- Fakes: one contract test suite run against both the fake and the SwiftData repository, so they
  cannot drift.

## Conventions touched in the same PR

- `architecture.md`: `DayKey` converts through its own `init(_:calendar:)`/`startDate(in:)` with an
  explicit calendar (the "only in Formatting/ and Persistence/" sentence is wrong once a view model
  needs today's key); the single `update(_:_:)` write path replaces "a method per action".
- Product spec: report weeks start on Monday regardless of locale.

## Left to the builder

- File split inside each folder, helper names, test fixture layout.
- Exact `swift-format` fixes.
