# Architecture

**Feature-first MVVM over a pure domain layer, with persistence behind repository protocols.
Dependencies go in through initializers; there are no singletons of our own.**

```
View ──▶ ViewModel ──▶ Repository protocol ◀── SwiftData repository ──▶ @Model records
              │                 │
              └──▶ Domain (Models/): value types + pure logic ◀── everything depends on it
```

Arrows point at what a layer may import. The domain depends on nothing; persistence is the only
layer that knows SwiftData exists.

## Folders

The app source folder `CleanLog/` is one `PBXFileSystemSynchronizedRootGroup`: a file dropped into
the tree is in the target, no "Add Files" step. Tests live in `CleanLogTests/`, mirroring the
source folders.

| Folder | Holds | May import |
|---|---|---|
| `App/` | `CleanLogApp`, `RootView` (the `TabView`), `AppDependencies` (builds the container and the real repositories) | everything |
| `Features/<Feature>/` | one feature's view, view model, subviews, presentation models, `<Feature>Layout` | `Models/`, `Repositories/`, `UICommons/`, `Formatting/` |
| `Models/` | domain value types and pure domain logic | Foundation only |
| `Repositories/` | repository protocols, their in-memory fakes and `StoreObservers` (the stream helper both implementations share) | `Models/` |
| `Persistence/` | `@Model` records, record ↔ domain mapping, SwiftData repositories, `ModelContainer` setup | SwiftData, `Models/`, `Repositories/` |
| `Formatting/` | every formatter: dates, money, durations, the report text | Foundation, `Models/` |
| `UICommons/` | views and modifiers used by two or more features | SwiftUI only |
| `Resources/` | `Assets.xcassets`, `Localizable.xcstrings` | — |

Features: `Today` (the day screen, today or any past day), `DayPlan` (the add-apartments sheet),
`Calendar`, `Stats`, `Report`, `Apartments` (the template), `Settings`.

- **Organize by feature, never by layer inside the app.** No top-level `Views/` or `ViewModels/`.
- A type referenced by two features moves to `Models/` (domain) or `UICommons/` (view) the moment
  the second one needs it. Two copies that agree today is not one rule that cannot disagree.
- **An extension of our type lives beside the type; an extension of a foreign type lives where it
  is used.** There is no `Extensions/` folder.
- A type that only serves one neighbour lives in the neighbour's file, supporting type first.
- A type spanning more than one file gets its own subfolder (`Models/WorkDay/`).

## Domain (`Models/`)

- **Domain types are value types**: `struct`/`enum`, `Sendable`, `Equatable`, no SwiftData, no
  SwiftUI. `Apartment`, `WorkDay`, `DayEntry`, `WorkSession`, `Money`, `DayKey`.
- **Logic is pure functions over domain values**: `MonthTotals.calculate(days:)`,
  `WorkDay.workedDuration(now:)`, `ReportBuilder.lines(for:)`. They take `now`/`calendar` as
  parameters instead of reading the clock, so a test can pin them.
- **Calculators return numbers, presentation models format them.** `MonthTotals` is `Money` and
  `Int`s; `StatsSummary.init(totals:)` in `Features/Stats/` produces the display strings. Checking a
  sum must never depend on the device locale.
- **Money is `Money(minorUnits: Int)`, never `Double` or `Decimal` arithmetic.** 28 zł is
  `Money(minorUnits: 2800)`. Integer sums are exact. The app is złoty-only for now: no currency
  setting, `MoneyFormat` always renders PLN. Supporting another currency later means adding it to
  `Money` and a setting, not changing how amounts are stored.
- **A calendar day is `DayKey(year:month:day:)`, never a `Date` at midnight.** A start-of-day `Date`
  moves when the time zone changes (a trip abroad would shift every day by one). `DayKey` is
  `Comparable`, `Hashable` and converts to and from `Date` only through its own
  `init(_:calendar:)` and `startDate(in:)`, always with an explicit `Calendar`.
- **Snapshots, not references, for history.** A `DayEntry` copies the apartment's name, price and
  report flag when it is planned, so editing or deleting an apartment never rewrites a past month.
  Deleting an apartment leaves history intact: entries keep their snapshots.

## Persistence (`Persistence/`)

- **`@Model` classes are persistence records, private to this folder** (`ApartmentRecord`,
  `WorkDayRecord`, …). They map to domain structs in `Record+Domain.swift` files; nothing outside
  `Persistence/` and `App/` writes `import SwiftData`. `@Model` classes are not `Sendable` and drag
  the store into every view that touches them — the mapping is the price of a domain that tests
  without a container.
- **Records stay CloudKit-compatible** so iCloud sync can be turned on later without a migration:
  every attribute optional or defaulted, every relationship optional, no `@Attribute(.unique)`.
  Uniqueness (one `WorkDay` per `DayKey`, one entry per apartment per day) is enforced by the
  repository.
- **Schema changes go through `VersionedSchema` + `SchemaMigrationPlan`** from the first release
  that reaches TestFlight. Never change a shipped record in place.
- **One `ModelContainer`, created in `AppDependencies`.** Repositories receive the container and
  work on its `mainContext` (a `ModelContext` does not keep its container alive); previews and
  tests use `ModelConfiguration(isStoredInMemoryOnly: true)`.

## Repositories (`Repositories/`)

- Protocols per aggregate: `ApartmentRepository`, `WorkDayRepository`, `SettingsRepository`.
  They speak domain types only. Each has an in-memory `Fake…Repository` beside it for previews and
  view-model tests.
- **Reads are observable streams**: `func days(in month: MonthKey) -> AsyncStream<[WorkDay]>`.
  The SwiftData implementation yields again after every save it performs (and, once sync exists,
  on remote change), so every screen showing the same day stays in step without manual refreshes.
- Writes are `async throws`. Apartments have one write per intent (`add`, `update`, `delete`).
  A day has a single write path, `update(_:_:)`, which hands the stored day (or an empty
  one) to a change closure and saves what it returns: the rules (`planning`, `settingCleaned`, the
  timer) live on `WorkDay` as pure functions, so a refused change throws its typed error and leaves
  the stored day untouched.

## View models

- **`@Observable @MainActor final class`**, never `ObservableObject`/`@Published`. A view owns its
  view model with `@State private var viewModel: TodayViewModel`, built in the view's `init` from
  injected dependencies.
- **Dependencies come through `init`**, typed as protocols. `AppDependencies` is passed down through
  the environment (`@Environment(AppDependencies.self)`) only to the point where a view builds its
  view model — view models themselves never read the environment.
- A view model exposes **presentation state, not records**: `rows: [ApartmentRow]`,
  `earnedText: String`. Views never call a formatter or touch a domain calculation.
- Subscriptions start in `func observe() async`, called from the view's `.task`, so SwiftUI cancels
  them when the view leaves. No `Task {}` stored in a view model, no `deinit` cleanup.
- **The view model does the work, the view routes.** Input validation, derived flags
  (`canSave`), and every write live in the view model; the view binds, presents and calls.

## Views

- **A view's `body` is layout, not logic.** Past ~40 lines, extract subviews as `struct`s in the
  same file, not computed `some View` properties: structs get their own identity and skip
  re-rendering when their inputs don't change.
- **Layout numbers live in a nested `private enum Layout`** in the view (or `<Feature>Layout` in a
  feature-local file when several views share them). No magic numbers in modifiers.
- **Navigation**: one `NavigationStack` per tab, routes as a feature-local `enum` used with
  `navigationDestination(for:)`. Sheets that share a screen are one optional enum and one
  `.sheet(item:)` with a `switch`, not a `@State` bool per sheet.
- **The tab bar is the system `TabView` with the `Tab` API.** It renders Liquid Glass on iOS 26 and
  the standard bar on 18 from the same code. Never a custom tab bar.
- Accessibility is part of done: every icon-only control has an `accessibilityLabel`, every row a
  combined element where it reads as one thing, and layouts survive the largest Dynamic Type size.

## Concurrency

- **Swift 6 language mode, default actor isolation `MainActor`, approachable concurrency on.**
  Everything is main-actor unless it says otherwise; there is no background work in this app worth
  the ceremony. **The exception is pure values: every type in `Models/` and `Formatting/` is declared
  `nonisolated`**, so neither the type nor its `Equatable`/`Hashable` conformances are bound to the
  main actor. Anything else marked `nonisolated` carries its reason in the same diff.
- **No `DispatchQueue`, no completion handlers, no Combine.** `async`/`await`, `AsyncStream`,
  `Task`, structured concurrency.
- A timer is `Clock`-driven (`ContinuousClock`/`Task.sleep(for:)`) or `TimelineView` for display;
  the stored state is start/end timestamps, never a counter that increments.

## Testing

- **Swift Testing** (`import Testing`, `@Test`, `#expect`, `@Suite`) in the `CleanLogTests` target;
  no XCTest except for UI tests.
- What must be tested: every pure function in `Models/` and `Formatting/` (the report formatter
  against the real October example), every view model against fakes, and each SwiftData
  repository against an in-memory container.
- Tests pin `now`, `Calendar` and `Locale`; a test that passes only in one time zone is a bug.
- `#Preview`s use fakes with fixture data from `<Feature>PreviewData.swift` (`#if DEBUG`).
