# Apartments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Apartments tab: a name-sorted template list with add, edit and confirmed swipe-delete,
backed by a domain without archiving or manual order.

**Architecture:** Four stacked branches. CL-10 changes the domain, persistence and repositories
(delete instead of archive, `ApartmentNameOrder` instead of `sortOrder`, report order). CL-11 adds
`MoneyInput` and the list view model, CL-13 the form view model, test-first against
`FakeApartmentRepository`. CL-12 builds the
screen, the sheet and the strings on those view models, with no logic of its own.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing, iOS 18.0+, Swift 6, default `MainActor` isolation.

**Spec:** `docs/superpowers/specs/2026-11-21-apartments-design.md` (and the product spec's Apartments
and Report sections).

## Global Constraints

- Every rule in `CLAUDE.md` and `.claude/conventions/` holds: no comments in Swift, no `print`, no `!`
  or `try!`, `private` by default, 3+ arguments one per line, every type in `Models/` and
  `Formatting/` is `nonisolated`.
- No user-facing literal in a view or view model: every string is a catalog key with uk and en,
  used through the generated symbol.
- Money is `Money(minorUnits:)`; display goes through `MoneyFormat`, input through `MoneyInput`.
- Every `#Preview` using fakes sits inside `#if DEBUG`; UI branches build Release too before the PR.
- Build: `xcodebuild -scheme CleanLog -destination 'generic/platform=iOS Simulator' build`; test:
  `xcodebuild -scheme CleanLog -destination 'platform=iOS Simulator,name=iPhone 16' test`
  (`-only-testing:CleanLogTests/<Suite>` for one suite); lint:
  `xcrun swift-format lint --strict --recursive CleanLog CleanLogTests`.
- Commits: imperative English subject, no attribution trailer.

## Review Focus

1. Price text a person may type: `28,50`, `28.5`, ` 28 `, `028`, an empty field, `28,505`, `-5`,
   `2 016`, twenty digits → `28,50`, `28.5`, ` 28 ` and `028` parse, the rest give `nil`; nothing
   crashes (Task 4).
2. A name that differs only by case or edge spaces from another (`6PIW` vs `6piw`, ` 100`) →
   «Квартира з такою назвою вже є», the sheet stays open; editing an apartment without renaming it
   saves (Task 6).
3. Deleting an apartment that is already gone (deleted from another screen) → an error message, no
   crash, the list stays consistent (Task 5).
4. Names the order must still sort sensibly: `054` vs `54`, `6PIW` vs `6piw`, `10a` vs `9b`, `100`
   vs `99` (Task 1).
5. Editing a price never changes a past day's entry (the existing `WorkDayPlanningTests` test that
   re-plans a repriced apartment and keeps 2800 must stay green after Task 2).

---

## Branch CL-10 — `feature/CL-10-apartment-delete-name-order` (base `main`)

Already holds the spec commit. Tasks 1–3.

### Task 1: The name order, and the report sorts by it

**Files:**
- Create: `CleanLog/Models/Apartment/ApartmentNameOrder.swift`
- Create: `CleanLogTests/Models/ApartmentNameOrderTests.swift`
- Modify: `CleanLog/Models/WorkDay/DayEntry.swift` (drop `sortOrder`)
- Modify: `CleanLog/Formatting/ReportBuilder.swift:39` (sort by the name order)
- Modify: `CleanLog/Persistence/SchemaV1.swift` (`DayEntryRecord.sortOrder` goes),
  `CleanLog/Persistence/WorkDayRecord+Domain.swift`
- Modify tests: `ReportBuilderTests.swift` (`listsSeparateApartmentsInTemplateOrder` →
  `listsApartmentsInNameOrder`, no `sortOrder:` arguments), `WorkDayPlanningTests.swift:25` (the
  `entry.sortOrder == 6` expectation goes)

**Interfaces:**
- Produces: `nonisolated enum ApartmentNameOrder { static func areInIncreasingOrder(_ lhs: String, _ rhs: String) -> Bool }`

- [ ] **Step 1: Write the failing tests** in `ApartmentNameOrderTests`

```swift
private func sorted(_ names: [String]) -> [String] {
    names.sorted(by: ApartmentNameOrder.areInIncreasingOrder)
}

@Test func putsDigitNamesFirstInNumericOrder() {
    #expect(sorted(["6piw", "100", "54", "133kol", "96"]) == ["54", "96", "100", "6piw", "133kol"])
}

@Test func comparesDigitNamesAsNumbers() {
    #expect(sorted(["100", "99", "1000"]) == ["99", "100", "1000"])
}

@Test func comparesOtherNamesNumericallyAndCaseInsensitively() {
    #expect(sorted(["10a", "9b", "Bravo", "alpha"]) == ["9b", "10a", "alpha", "Bravo"])
}

@Test func breaksTiesByPlainOrder() {
    #expect(sorted(["54", "054"]) == ["054", "54"])
    #expect(sorted(["6piw", "6PIW"]) == ["6PIW", "6piw"])
}
```

- [ ] **Step 2: Run** `-only-testing:CleanLogTests/ApartmentNameOrderTests` → fails to compile
  (`ApartmentNameOrder` not found).

- [ ] **Step 3: Implement `ApartmentNameOrder.areInIncreasingOrder(_:_:)`**: rank 0 for a non-empty
  name of only `"0"..."9"`, rank 1 otherwise; lower rank first; within a rank
  `lhs.compare(rhs, options: [.numeric, .caseInsensitive], range: nil, locale: nil)`; on
  `.orderedSame`, `lhs < rhs`.

- [ ] **Step 4: Run the suite** → PASS.

- [ ] **Step 5: Change the report and drop `DayEntry.sortOrder`**: `ReportBuilder.line(for:)` sorts
  cleaned entries with `ApartmentNameOrder.areInIncreasingOrder($0.name, $1.name)`. Remove
  `sortOrder` from `DayEntry`, both its initializers, `DayEntryRecord` and its mapping. Rewrite the
  report test as

```swift
@Test func listsApartmentsInNameOrder() {
    let mixed = WorkDay.fixture(
        DayKey(year: 2026, month: 11, day: 5),
        ticked: [
            .fixture("160", separate: true),
            .fixture("6piw"),
            .fixture("155", separate: true),
            .fixture("100"),
            .fixture("54"),
        ]
    )
    #expect(ReportBuilder.report(for: november, days: [mixed]) == "5.11-(54,100,6piw)=3+155+160")
}
```

  `Apartment.sortOrder` still exists until Task 2, so the fixtures still compile.

- [ ] **Step 6: Run** the full test suite → PASS, including `reproducesTheOctoberReport` (its
  shuffled input now comes out in name order, which is the boss's order).

- [ ] **Step 7: Commit** — `Sort report entries by apartment name`.

### Task 2: Delete instead of archive, no manual order

**Files:**
- Modify: `CleanLog/Models/Apartment/Apartment.swift` (drop `sortOrder`, `isArchived`,
  `nextSortOrder(after:)`; `init(_:sortOrder:createdAt:)` → `init(_ draft: ApartmentDraft, createdAt: Date)`)
- Modify: `CleanLog/Models/Apartment/ApartmentDraft.swift` (uniqueness against every apartment)
- Modify: `CleanLog/Repositories/ApartmentRepository.swift`, `FakeApartmentRepository.swift`
- Modify: `CleanLog/Persistence/SchemaV1.swift` (`ApartmentRecord.sortOrder`, `.isArchived` go),
  `ApartmentRecord+Domain.swift`, `SwiftDataApartmentRepository.swift`
- Modify tests: `Support/Fixtures.swift` (drop `sortOrder:` and `archived:`), every
  `sortOrder:`/`archived:` call site (`MonthStatsTests`, `WorkDayPlanningTests`,
  `WorkDayRecordMappingTests`, `WorkDayRepositoryContractTests`, `OctoberReport.template` — a plain
  `map`), `ApartmentDraftTests`, `ApartmentRecordMappingTests`, `ApartmentRepositoryContractTests`,
  `AppDependenciesTests`

**Interfaces:**
- Consumes: `ApartmentNameOrder.areInIncreasingOrder` (Task 1).
- Produces:

```swift
protocol ApartmentRepository: AnyObject {
    func apartments() -> AsyncStream<[Apartment]>
    func add(_ draft: ApartmentDraft) async throws -> Apartment
    func update(_ apartment: Apartment) async throws
    func delete(_ id: UUID) async throws
}
```

  `apartments()` yields in `ApartmentNameOrder` by `name`; `delete` throws `ApartmentError.notFound`
  for an unknown id.

- [ ] **Step 1: Rewrite the contract tests first.** In `ApartmentRepositoryContractTests`: every
  `apartments(includingArchived: false)` → `apartments()`; `addsApartmentsInOrder` →
  `listsApartmentsInNameOrder` adding `"100"`, `"6piw"`, `"54"` and expecting
  `["54", "100", "6piw"]` (drop the `sortOrder` expectation, keep the trim, code and `createdAt`
  ones); drop `stored.sortOrder == 0` in `updatesTheEditableFields`; delete `reordersByTheGivenIds`;
  replace `archivingHidesButKeeps` with

```swift
@Test(arguments: RepositoryKind.allCases)
func deletesAnApartment(kind: RepositoryKind) async throws {
    let repository = kind.makeStore(now: now).apartments
    let apartment = try await repository.add(draft("100"))
    _ = try await repository.add(draft("101"))

    try await repository.delete(apartment.id)

    var stream = repository.apartments().makeAsyncIterator()
    #expect(await stream.next()?.map(\.name) == ["101"])
    await #expect(throws: ApartmentError.notFound) { try await repository.delete(apartment.id) }
}

@Test(arguments: RepositoryKind.allCases)
func freesTheNameOfADeletedApartment(kind: RepositoryKind) async throws {
    let repository = kind.makeStore(now: now).apartments
    let apartment = try await repository.add(draft("100"))
    try await repository.delete(apartment.id)
    #expect(try await repository.add(draft("100")).name == "100")
}
```

  In `ApartmentDraftTests`: drop `archived`, `allowsTheNameOfAnArchivedApartment` and
  `sortsANewApartmentAfterEveryOther`; `existing` is `[active]`; the init test calls
  `Apartment(draft(...), createdAt:)` without the `sortOrder`/`isArchived` expectations; the applying
  test edits `active`.

- [ ] **Step 2: Run** the full tests → compile errors on the removed members.

- [ ] **Step 3: Implement.** Remove the members listed under Files. `ApartmentDraft.isName(_:takenIn:excluding:)`
  drops the `!apartment.isArchived` condition. Both repositories sort with
  `ApartmentNameOrder` instead of `sortOrder` (the SwiftData fetch loses its `SortDescriptor`) and
  implement `delete` (`context.delete(record)` then `save()`; the fake removes from `stored` then
  `notify()`). `SchemaV1` changes in place — the store has not reached TestFlight.

- [ ] **Step 4: Run** the full tests → PASS. Build → no warnings from the change.

- [ ] **Step 5: Commit** — `Delete apartments instead of archiving and drop the manual order`.

### Task 3: Docs follow the decisions

**Files:**
- Modify: `docs/superpowers/specs/2026-11-13-cleanlog-design.md` — Apartments section ("Add, edit,
  delete; sorted by name …"), the anti-goal "archiving an apartment erases history" → "deleting an
  apartment or changing a price rewrites past months", the data model (`Apartment` without
  `sortOrder`/`isArchived`, `DayEntry` without `sortOrder`), the report rule "Inside the brackets:
  entries in template order" → "in apartment name order: digit-only names numerically, then the
  rest".
- Modify: `.claude/conventions/architecture.md` — "Archiving is a flag; nothing that history refers
  to is ever deleted" → "Deleting an apartment leaves history intact: entries keep their snapshots";
  apartment writes `add`, `update`, `delete`; the snapshot bullet no longer says archiving.

- [ ] **Step 1: Edit both files** as above; nothing else in them changes.
- [ ] **Step 2: Commit** — `Describe deletion and name order in the spec and conventions`.

Then the branch review (`CLAUDE.md`: concurrency skill — the repositories; SOLID pass), build, full
tests, lint, `docs/plan.md`, push, PR to `main`.

---

## Branch CL-11 — `feature/CL-11-apartment-view-models` (base CL-10)

Tasks 4–5. No SwiftUI view in the diff.

### Task 4: `MoneyInput`

**Files:**
- Create: `CleanLog/Formatting/MoneyInput.swift`, `CleanLogTests/Formatting/MoneyInputTests.swift`

**Interfaces:**
- Produces: `nonisolated enum MoneyInput { static func parse(_ text: String) -> Money?; static func string(_ money: Money, locale: Locale = .current) -> String }`

- [ ] **Step 1: Write the failing tests**

```swift
@Test(arguments: [
    ("28", 2800), ("28,50", 2850), ("28.5", 2850), (" 28 ", 2800), ("028", 2800), ("0", 0),
])
func parsesAPrice(text: String, minorUnits: Int) {
    #expect(MoneyInput.parse(text) == Money(minorUnits: minorUnits))
}

@Test(arguments: ["", " ", "28,505", "-5", "2 016", "28,", ",5", "abc", "1e3", "99999999999999999999"])
func rejectsWhatIsNotAPrice(text: String) {
    #expect(MoneyInput.parse(text) == nil)
}

@Test func writesAPriceForEditing() {
    #expect(MoneyInput.string(Money(minorUnits: 2800), locale: Locale(identifier: "uk_UA")) == "28")
    #expect(MoneyInput.string(Money(minorUnits: 2850), locale: Locale(identifier: "uk_UA")) == "28,50")
    #expect(MoneyInput.string(Money(minorUnits: 2850), locale: Locale(identifier: "en_US")) == "28.50")
    #expect(MoneyInput.string(Money(minorUnits: 201_600), locale: Locale(identifier: "en_US")) == "2016")
}

@Test func readsBackWhatItWrites() {
    let price = Money(minorUnits: 3550)
    #expect(MoneyInput.parse(MoneyInput.string(price, locale: Locale(identifier: "pl_PL"))) == price)
}
```

- [ ] **Step 2: Run** `-only-testing:CleanLogTests/MoneyInputTests` → fails to compile.
- [ ] **Step 3: Implement.** `parse`: trim whitespace; whole part 1+ ASCII digits, optional `,` or `.`
  with 1–2 ASCII digits; `Int(whole)` must succeed and `whole * 100 + fraction` must not overflow
  (`multipliedReportingOverflow`), else `nil`; one fraction digit means tens (`5` → 50). `string`:
  no grouping, no fraction when whole, otherwise two digits after `locale.decimalSeparator ?? "."`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `Add parsing and writing of a typed price`.

### Task 5: `ApartmentsViewModel`

**Files:**
- Create: `CleanLog/Features/Apartments/ApartmentRow.swift`, `ApartmentSheet.swift`,
  `ApartmentsViewModel.swift`
- Create: `CleanLogTests/Support/Eventually.swift`,
  `CleanLogTests/Features/Apartments/ApartmentsViewModelTests.swift`
- Modify: `CleanLog/Resources/Localizable.xcstrings` (`apartments.error.delete`)

**Interfaces:**
- Consumes: `ApartmentRepository` (Task 2), `MoneyFormat`.
- Produces:

```swift
struct ApartmentRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let priceText: String
    let isReportedSeparately: Bool
}  // init(_ apartment: Apartment, locale: Locale)

enum ApartmentSheet: Identifiable, Equatable {
    case new
    case edit(Apartment)
}  // var id: UUID? — nil for .new, the apartment's id for .edit

@Observable final class ApartmentsViewModel {
    init(repository: any ApartmentRepository, locale: Locale = .current)
    private(set) var rows: [ApartmentRow]
    var showsEmptyState: Bool        // true only after the first yield and with no rows
    var count: Int
    var sheet: ApartmentSheet?
    private(set) var pendingDeletion: ApartmentRow?
    var isConfirmingDeletion: Bool   // pendingDeletion != nil; setting false clears it
    private(set) var errorMessage: String?
    var isShowingError: Bool         // errorMessage != nil; setting false clears it
    func observe() async
    func add()
    func edit(_ id: UUID)
    func requestDeletion(_ id: UUID)
    func cancelDeletion()
    func confirmDeletion() async
    func makeFormViewModel(for sheet: ApartmentSheet) -> ApartmentFormViewModel
}
```

  `makeFormViewModel` is added in Task 6 (it needs `ApartmentFormViewModel`).

- [ ] **Step 1: Add the test helper** `func eventually(_ condition: () -> Bool) async` in
  `Eventually.swift`: up to 1 000 `await Task.yield()` until the condition holds, else
  `Issue.record("condition never held")`.
- [ ] **Step 2: Write the failing tests** (each starts `let task = Task { await viewModel.observe() }`
  and ends `task.cancel()`; the fake is seeded through `FakeApartmentRepository([...])`, locale
  `uk_UA`):

```swift
@Test func listsRowsInNameOrder() async {
    // seeded "6piw", "106" (5600, separate), "54"
    await eventually { viewModel.rows.count == 3 }
    #expect(viewModel.rows.map(\.name) == ["54", "106", "6piw"])
    #expect(viewModel.rows[1].priceText == "56\u{00A0}zł")
    #expect(viewModel.rows[1].isReportedSeparately)
    #expect(viewModel.count == 3)
    #expect(!viewModel.showsEmptyState)
}

@Test func showsTheEmptyStateOnlyOnceLoaded() async {
    #expect(!viewModel.showsEmptyState)
    let task = Task { await viewModel.observe() }
    await eventually { viewModel.showsEmptyState }
    task.cancel()
}

@Test func opensTheSheets() async {
    viewModel.add()
    #expect(viewModel.sheet == .new)
    viewModel.edit(a100.id)
    #expect(viewModel.sheet == .edit(a100))
}

@Test func deletesOnlyAfterConfirmation() async {
    viewModel.requestDeletion(a100.id)
    #expect(viewModel.pendingDeletion?.name == "100")
    viewModel.cancelDeletion()
    #expect(viewModel.pendingDeletion == nil)
    viewModel.requestDeletion(a100.id)
    await viewModel.confirmDeletion()
    await eventually { viewModel.rows.map(\.name) == ["101"] }
    #expect(viewModel.pendingDeletion == nil)
}

@Test func reportsAFailedDeletion() async throws {
    viewModel.requestDeletion(a100.id)
    try await repository.delete(a100.id)
    await viewModel.confirmDeletion()
    #expect(viewModel.errorMessage != nil)
    #expect(viewModel.pendingDeletion == nil)
    viewModel.isShowingError = false
    #expect(viewModel.errorMessage == nil)
}

@Test func confirmsADeletionOnce() async {
    viewModel.requestDeletion(a100.id)
    await viewModel.confirmDeletion()
    await viewModel.confirmDeletion()
    #expect(viewModel.errorMessage == nil)
}
```

- [ ] **Step 3: Run** `-only-testing:CleanLogTests/ApartmentsViewModelTests` → fails to compile.
- [ ] **Step 4: Implement.** The view model keeps the last `[Apartment]` from the stream (for
  `edit` and `requestDeletion`, which ignore an unknown id); `rows` map it with `ApartmentRow(_:locale:)`
  (`MoneyFormat.string`). `confirmDeletion()` takes `pendingDeletion` into a local and clears it
  **before** `await repository.delete` (a second tap during the await finds nothing to delete). A
  failed delete sets `errorMessage` from `apartments.error.delete`
  («Не вдалося видалити квартиру.» / "Couldn't delete the
  apartment."). Add that key to the catalog in both languages.
- [ ] **Step 5: Run** → PASS.
- [ ] **Step 6: Commit** — `Add the apartments list view model`.

## Branch CL-13 — `feature/CL-13-apartment-form-view-model` (base CL-11)

Task 6, split from CL-11 when that branch came to 701 lines. No SwiftUI view in the diff.

### Task 6: `ApartmentFormViewModel`

**Files:**
- Create: `CleanLog/Features/Apartments/ApartmentFormViewModel.swift`,
  `CleanLogTests/Features/Apartments/ApartmentFormViewModelTests.swift`
- Modify: `ApartmentsViewModel.swift` (`makeFormViewModel(for:)`), its tests,
  `Localizable.xcstrings`

**Interfaces:**
- Consumes: `MoneyInput` (Task 4), `ApartmentSheet` (Task 5), `ApartmentRepository`.
- Produces:

```swift
@Observable final class ApartmentFormViewModel {
    init(repository: any ApartmentRepository, editing apartment: Apartment?, locale: Locale = .current)
    var name: String                 // setting it clears nameError
    var priceText: String
    var accessCode: String
    var isReportedSeparately: Bool
    var title: String                // the apartment's name when editing, else apartments.form.title.new
    var canSave: Bool                // non-blank name, parseable price, not saving
    private(set) var nameError: String?
    private(set) var errorMessage: String?
    var isShowingError: Bool         // errorMessage != nil; setting false clears it
    func save() async -> Bool        // true: saved, close the sheet
}
```

- [ ] **Step 1: Write the failing tests** (locale `uk_UA`, a seeded fake with `a100` 28 zł and
  `a6piw`):

```swift
@Test func startsBlankForANewApartment() {
    let form = makeForm(editing: nil)
    #expect(form.name.isEmpty && form.priceText.isEmpty && form.accessCode.isEmpty)
    #expect(!form.isReportedSeparately)
    #expect(!form.canSave)
}

@Test func prefillsAnEditedApartment() {
    let form = makeForm(editing: a100WithCode)   // 2850, code "4821", separate
    #expect(form.title == "100")
    #expect(form.priceText == "28,50")
    #expect(form.accessCode == "4821")
    #expect(form.isReportedSeparately)
}

@Test(arguments: [("   ", "28", false), ("106", "", false), ("106", "28,505", false), ("106", "56", true)])
func enablesSaveForAValidForm(name: String, price: String, canSave: Bool) {
    let form = makeForm(editing: nil)
    form.name = name
    form.priceText = price
    #expect(form.canSave == canSave)
}

@Test func addsANewApartment() async {
    let form = makeForm(editing: nil)
    form.name = " 106 "; form.priceText = "56"; form.isReportedSeparately = true
    #expect(await form.save())
    // the repository stream now holds "106" at 5600, separate, accessCode nil
}

@Test func updatesAnEditedApartment() async {
    let form = makeForm(editing: a100)
    form.priceText = "30"
    #expect(await form.save())
    // the stored a100 has price 3000 and the same id
}

@Test func keepsTheSheetOpenOnADuplicateName() async {
    let form = makeForm(editing: nil)
    form.name = "6PIW"; form.priceText = "28"
    #expect(await !form.save())
    #expect(form.nameError != nil)
    form.name = "7piw"
    #expect(form.nameError == nil)
}

@Test func reportsAFailedUpdate() async throws {
    let form = makeForm(editing: a100)
    try await repository.delete(a100.id)
    #expect(await !form.save())
    #expect(form.errorMessage != nil)
}
```

  In `ApartmentsViewModelTests`, `makesAFormForTheSheet`: `.new` gives a blank title-new form,
  `.edit(a100)` a form titled `"100"`.

- [ ] **Step 2: Run** `-only-testing:CleanLogTests/ApartmentFormViewModelTests` → fails to compile.
- [ ] **Step 3: Implement.** `save()` builds `ApartmentDraft(name:price:accessCode:isReportedSeparately:)`
  from the fields (the draft trims and normalizes) and calls `add` or
  `update(apartment.applying(draft))`; `ApartmentError.duplicateName` → `nameError`, any other error →
  `errorMessage`. `save()` returns `false` at once while a save is running, sets the saving flag
  before the `await` and clears it with `defer` (`canSave` is false meanwhile, so a double tap saves
  once). Catalog keys, both languages:
  - `apartments.form.title.new` — «Нова квартира» / "New apartment"
  - `apartments.form.error.duplicateName` — «Квартира з такою назвою вже є» / "An apartment with this name already exists"
  - `apartments.form.error.save` — «Не вдалося зберегти квартиру.» / "Couldn't save the apartment."
- [ ] **Step 4: Run** both view-model suites → PASS.
- [ ] **Step 5: Commit** — `Add the apartment form view model`.

Then the branch review (`swiftui-pro` and `swift-concurrency-pro` on the view models; SOLID pass),
build, tests, lint, `docs/plan.md`, push, PR to CL-11's branch (or `main` once merged).

---

## Branch CL-12 — `feature/CL-12-apartments-screen` (base CL-13)

Tasks 7–8. Layout and bindings only; every decision is already in a view model.

### Task 7: The list, the empty state and delete

**Files:**
- Modify: `CleanLog/Features/Apartments/ApartmentsView.swift`, `CleanLog/App/RootView.swift`
- Create: `CleanLog/Features/Apartments/ApartmentRowView.swift`,
  `CleanLog/Features/Apartments/ApartmentsPreviewData.swift` (`#if DEBUG`)
- Modify: `Localizable.xcstrings`

**Interfaces:**
- Consumes: `ApartmentsViewModel` (Tasks 5–6).
- Produces: `ApartmentsView(repository: any ApartmentRepository)`; `RootView` reads
  `@Environment(AppDependencies.self)` and passes `dependencies.apartments`.

- [ ] **Step 1: Strings** (uk / en):
  - `apartments.count` — plural on `%lld`: «%lld квартира / квартири / квартир» /
    "%lld apartment / apartments"
  - `apartments.footnote` — «Нова ціна діє лише для наступних прибирань — минулі місяці не
    змінюються.» / "A new price applies to future cleanings only — past months stay as they were."
  - `apartments.badge.separate` — «окремо у звіті» / "separate in report"
  - `apartments.action.add` — «Нова квартира» / "New apartment"
  - `apartments.empty.title` — «Додай свої квартири» / "Add your apartments"
  - `apartments.empty.action` — «Додати квартиру» / "Add apartment"
  - `apartments.delete.action` — «Видалити» / "Delete"
  - `apartments.delete.title` — «Видалити %@?» / "Delete %@?"
  - `apartments.delete.message` — «Минулі прибирання лишаться у звітах.» / "Past cleanings stay in
    your reports."
  - `common.action.cancel` — «Скасувати» / "Cancel"
- [ ] **Step 2: Build the view.** `ApartmentsView` owns `@State private var viewModel`, built in
  `init(repository:)`; `.task { await viewModel.observe() }`. A `List` with one section: header the
  count, footer the footnote, rows `ApartmentRowView` on `Color.card` (`listRowBackground`),
  `.scrollContentBackground(.hidden)` over `Color.background`. Tap a row → `viewModel.edit(id)`;
  `.swipeActions` with a destructive `apartments.delete.action` → `requestDeletion(id)`.
  `showsEmptyState` → `ContentUnavailableView` with `building.2`, the empty title and an
  `apartments.empty.action` button → `add()`. Toolbar `+` (`plus`, label `apartments.action.add`) →
  `add()`. The confirmation is
  `.alert(title, isPresented: $viewModel.isConfirmingDeletion, presenting: viewModel.pendingDeletion)`
  (title with the name, the message, destructive delete → `confirmDeletion()`, cancel →
  `cancelDeletion()`); errors `.alert(viewModel.errorMessage ?? "", isPresented: $viewModel.isShowingError) {}`
  — no actions, so the system's single OK. No `Binding(get:set:)` in the body. `.sheet(item: $viewModel.sheet)` shows a placeholder until Task 8.
  `ApartmentRowView`: name (`.body.weight(.semibold)`), the badge (`.caption.weight(.semibold)`,
  `Color.accent` on `Color.accentSoft`, capsule), price (`InkSecondary`, `.monospacedDigit()`),
  chevron; `.accessibilityElement(children: .combine)`; layout numbers in `private enum Layout`.
- [ ] **Step 3: Previews** inside `#if DEBUG`: a filled list and the empty state from
  `ApartmentsPreviewData` (the October template names with 28 zł and `155` at 56 zł separate).
- [ ] **Step 4: Build** Debug and Release, run on the iPhone 16 simulator: empty state → add is
  wired; with preview data the list, the swipe and the alert look right in light, dark and the
  largest Dynamic Type size.
- [ ] **Step 5: Commit** — `Show the apartment template list`.

### Task 8: The form sheet

**Files:**
- Create: `CleanLog/Features/Apartments/ApartmentFormView.swift`
- Modify: `ApartmentsView.swift` (the sheet), `Localizable.xcstrings`

**Interfaces:**
- Consumes: `ApartmentsViewModel.makeFormViewModel(for:)`, `ApartmentFormViewModel` (Task 6).
- Produces: `ApartmentFormView(viewModel: ApartmentFormViewModel)`.

- [ ] **Step 1: Strings**: `apartments.form.field.name` «Назва» / "Name";
  `apartments.form.field.price` «Ціна» / "Price"; `apartments.form.field.accessCode`
  «Код доступу» / "Access code"; `apartments.form.placeholder.optional`
  «Необов'язково» / "Optional"; `apartments.form.field.separate` «Окремо у звіті» / "Separate in report"; `common.action.save` «Зберегти» / "Save".
- [ ] **Step 2: Build the sheet.** A `NavigationStack` with a `Form`: name `TextField` (the
  `nameError` under it in `Color.warning`, `.footnote`), price `TextField` with `.keyboardType(.decimalPad)`
  and a trailing «zł» that is not localized (`Text(verbatim:)` — the currency symbol, like
  `MoneyFormat`'s), access code `TextField` with the optional placeholder, the separate `Toggle`.
  Toolbar: cancel (`.cancellationAction`, `dismiss()`), save (`.confirmationAction`,
  `.disabled(!viewModel.canSave)`, `if await viewModel.save() { dismiss() }`). `.navigationTitle(viewModel.title)`,
  inline. `.presentationDetents([.medium, .large])`. Errors → the same action-less alert on
  `$viewModel.isShowingError`. In `ApartmentsView`,
  `.sheet(item:)` builds `ApartmentFormView(viewModel: viewModel.makeFormViewModel(for: sheet))`.
- [ ] **Step 3: Preview** inside `#if DEBUG`: new and edit.
- [ ] **Step 4: Build** Debug and Release; on the simulator add an apartment, edit its price, try a
  duplicate name, delete it; check the sheet at the largest Dynamic Type size (it can grow to full
  height) and the iOS 18 simulator if installed.
- [ ] **Step 5: Commit** — `Add the apartment form sheet`.

Then the branch review (`swiftui-pro`; SOLID pass), build Debug and Release, full tests, lint,
`docs/plan.md` (Feature 3 done), push, PR.

### CL-12 rework (2026-11-21) — the big add button and the centered form

The user reviewed the built screen; the spec's "Revision after the first screen review" section
replaces decisions 3 and 5. Three more tasks on the same branch: logic first (Task 9), then UI.
The branch ends the feature, so it may pass 500 lines (most of the overflow is catalog JSON).

**Review Focus (rework):**
1. A double tap on «Зберегти» in the popup → one apartment, the card closes once.
2. The keyboard on a small phone (iPhone SE size) → the focused field and the buttons stay visible.
3. The largest Dynamic Type size → the card scrolls, the two buttons stack, nothing is cut off.
4. A tap on the blurred backdrop → nothing happens; VoiceOver's escape gesture → cancels.
5. The last apartment in a long list → can scroll above the pinned button and be tapped.

### Task 9: The form says whether it adds, not a title

**Files:** Modify `ApartmentFormViewModel.swift`, `ApartmentFormViewModelTests.swift`,
`ApartmentsViewModelTests.swift`, `Localizable.xcstrings`.

**Interfaces:** Produces `ApartmentFormViewModel.isAdding: Bool` (true when built with
`editing: nil`). Removes `title` and the `apartments.form.title.new` key.

- [ ] **Step 1: Tests.** In `startsBlankForANewApartment` replace the title line with
  `#expect(form.isAdding)`; in `prefillsAnEditedApartment` with `#expect(!form.isAdding)`; in
  `makesAFormForTheSheet` `#expect(newForm.isAdding)` and `#expect(!editForm.isAdding)`.
- [ ] **Step 2: Run** `-only-testing:CleanLogTests/ApartmentFormViewModelTests` → fails to compile
  (`isAdding` missing).
- [ ] **Step 3: Implement** `var isAdding: Bool { apartment == nil }`; delete `title`; delete the
  `apartments.form.title.new` key. The form view keeps compiling until Task 11 by dropping its
  `.navigationTitle` line now.
- [ ] **Step 4: Run** both apartment view model suites → pass.
- [ ] **Step 5: Commit** — `Tell the form whether it adds instead of giving it a title`.

### Task 10: The big «Додати квартиру» button

**Files:** Modify `ApartmentsView.swift`, `Localizable.xcstrings`.

- [ ] **Step 1: Strings.** `apartments.action.add` becomes «Додати квартиру» / "Add apartment";
  delete `apartments.empty.action`.
- [ ] **Step 2: View.** Remove the toolbar. A private `AddApartmentButton` (in `ApartmentsView.swift`):
  `Label` with `plus` and `apartments.action.add`, full width, `.buttonStyle(.borderedProminent)`,
  `.buttonBorderShape(.capsule)`, `.controlSize(.extraLarge)` (`.large` below iOS 26 if it does not
  exist there), `.font(.headline)`. Pinned with `.safeAreaInset(edge: .bottom)` on the `Group`
  holding the list or the empty state, horizontal and bottom padding from `private enum Layout`.
  `ApartmentsEmptyState` keeps its label and loses its action and its `viewModel`.
- [ ] **Step 3: Build** and look at the empty state and the list (the last row scrolls above the
  button) on the simulator, light and largest text.
- [ ] **Step 4: Commit** — `Pin a big add button to the bottom of the apartments screen`.

### Task 11: The centered form popup

**Files:** Modify `ApartmentFormView.swift`, `ApartmentsView.swift`.

**Interfaces:** Consumes `ApartmentFormViewModel.isAdding` (Task 9). `ApartmentFormView(viewModel:)`
stays the entry point.

- [ ] **Step 1: Presentation.** `ApartmentsView` swaps `.sheet(item:)` for `.fullScreenCover(item:)`
  with the same route. The system slide is switched off: every call that sets the route (`add`,
  `edit`) runs inside `withTransaction(\.disablesAnimations, true) { … }` in the view; the form's
  dismissal does the same. The cover gets `.presentationBackground(.clear)`.
- [ ] **Step 2: The card.** `ApartmentFormView` drops `NavigationStack`, `Form`, the toolbar and the
  detents. A full-screen `Rectangle().fill(.thinMaterial).ignoresSafeArea()` backdrop with no tap
  action; above it, centered in a `ScrollView` that fills the screen (scrolls only when the card is
  taller), a `VStack` card with the four rows separated by `Color.hairline` dividers, `NameField`'s
  error under its row, and the buttons, on `.cardSurface()`, horizontal margin from `Layout`. Rows
  keep `LabeledContent` (it stacks label and field at accessibility sizes).
- [ ] **Step 3: Buttons.** `FormButtons` (private): `ViewThatFits(in: .horizontal)` of an `HStack`
  (cancel, save) and a `VStack` (save, cancel); both full width; save `.borderedProminent`, cancel
  `.bordered`, both `.buttonBorderShape(.capsule)`, `.controlSize(.large)`; save disabled by
  `!viewModel.canSave`. `common.action.cancel` / `common.action.save`.
- [ ] **Step 4: Motion and focus.** `@State private var isShown = false`: on appear
  `withAnimation(.snappy) { isShown = true }`; the card's `opacity` and `scaleEffect` (0.94 → 1) and
  the backdrop's `opacity` follow it. `close()` animates `isShown = false` and dismisses in the
  animation's completion (without the system animation). Cancel and a successful save call
  `close()`; `.accessibilityAction(.escape)` calls it too. `@FocusState` on the name field, set on
  appear when `viewModel.isAdding`.
- [ ] **Step 5: Build** Debug and Release; on the simulator (temporary, uncommitted tweak to open the
  popup): new and edit, light, dark, largest text, Ukrainian; the keyboard with the name focused.
- [ ] **Step 6: Commit** — `Show the apartment form as a centered popup`.

Then the branch review again on the whole CL-12 diff (`swiftui-pro`, SOLID pass), build Debug and
Release, full tests, lint, `docs/plan.md`, push (the open PR updates; rewrite its description).

---

## Plan review (2026-11-21)

- `swiftui-pro`: the alerts were bound to optionals, which needs `Binding(get:set:)` in the body →
  the view models expose `isConfirmingDeletion` and `isShowingError` as settable flags; the error
  alert has no actions (the system OK), so no `common.action.ok` key. Kept: the price field binds to
  `String` through `MoneyInput`, not `TextField(value:format:)` — `Money` has no format style, and a
  value-bound field commits only on submit, so `canSave` could not follow the typing.
- `swift-concurrency-pro`: `confirmDeletion()` clears `pendingDeletion` before its `await`, and
  `save()` refuses a second call while one runs (state read after a suspension is stale; a double
  tap would delete or add twice) — test `confirmsADeletionOnce` added. Kept: `eventually(_:)` polls
  with bounded `Task.yield()`s, because `observe()` never returns and the stream's first value is
  not otherwise awaitable; the test target is default `MainActor`, so the `Task` running
  `observe()` and the assertions share the main actor.
