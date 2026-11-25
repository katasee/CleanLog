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

## Feature 1 — Foundation (done)

The plan and design files were deleted once the feature merged (CL-8); the notes below stay as the
record.

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 1 | `feature/CL-1-test-target-day-keys` | `main` | 1–2 | 481 | merged (PR #1) | done — concurrency clean; SOLID: 3 fixes + convention sync (below) |
| 2 | `feature/CL-2-apartment-workday` | `main` | 3–4 | 469 | merged (PR #2) | done — concurrency clean; SOLID: 5 fixes (below) |
| 3 | `feature/CL-3-timer-stats` | `main` | 5–6 | 353 | merged (PR #3) | done — concurrency clean; SOLID: 6 fixes (below) |
| 4 | `feature/CL-4-report-formatters` | `main` | 7–8 | 294 | merged (PR #4) | done — concurrency clean; SOLID: 5 fixes + spec sync (below) |
| 5 | `feature/CL-5-repositories` | `main` | 9 | 504 | merged (PR #5) | done — concurrency: 1 test fix; SOLID: 1 fix (below) |
| 6 | `feature/CL-6-swiftdata` | `main` | 10 | 563 | merged (PR #6) | done — concurrency clean; SOLID: 3 fixes (below) |
| 7 | `feature/CL-7-app-wiring` | `main` | 11 | ~95 (end of feature) | merged (PR #7) | done — SwiftUI: 1 fix; SOLID clean (below) |

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
- CL-7 (2026-11-21): PR #6 was merged, so CL-7 starts from `main` and its PR targets `main`.
  Deviation from the plan: `AppDependencies` does not keep the `ModelContainer` — since CL-6 the
  SwiftData repositories hold it, so a third reference would be dead state. Of the docs step, the
  `DayKey`/`Date` sentence (CL-1) and the Monday weeks in the product spec (CL-4) were already done;
  this branch rewrote the repository-writes bullet (one write per intent for apartments, the single
  `update(_:_:)` path for days) and put `StoreObservers` in the `Repositories/` row. Launched on the
  iPhone 16 simulator: the template screen shows and `default.store` is created. SwiftUI review:
  `#Preview` compiles in Release too, so `ContentView`'s preview calling the debug-only
  `AppDependencies.preview()` broke the Release build → the template preview no longer injects
  dependencies (it reads none). **Every later `#Preview` that uses fakes or `preview()` must sit
  inside `#if DEBUG`**, and a Release build belongs to the pre-PR check for UI branches. Kept: the
  template `ContentView` with its "Hello, world!" literal stays until the shell replaces it (the
  foundation spec allows it; there is no String Catalog yet). SOLID / clean code: no findings —
  `AppDependencies` only composes, and exposes the repositories as protocols.
- Branch 4 is under 300 lines on purpose: it closes the pure-logic half of the foundation.

## Feature 2 — Design system (done)

The plan and design files were deleted once the feature merged (CL-9); the notes below stay as the
record.

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 8 | `feature/CL-8-design-system` | `main` | 1–3 | 634 | merged (PR #8) | done — SwiftUI clean; SOLID clean; 1 convention fix (below) |
| 9 | `feature/CL-9-tab-shell` | `main` | 4–5 | 178 (end of feature) | merged (PR #9) | done — SwiftUI: 1 tidy-up; SOLID: 1 fix (below) |

Notes for the sessions:

- Brainstorming (2026-11-21): the canvas's colour variants were dropped, so one teal palette and no
  themes. The floating add button moves to Feature 5 (Day plan), since it opens that sheet. No
  blurred blobs behind the screens: the flat `Background` token. Plan reviewed with `swiftui-pro`
  before code (no blocking findings, see the plan file).
- Sizes leave out the deleted foundation docs (a pure deletion of ~440 lines in CL-8).
- CL-8 (2026-11-21): the `Separator` colorset collided with `UIColor.separator` (Xcode skipped its
  generated symbol with a warning) → renamed `Hairline`; `code-style.md` table and its naming rule
  updated in the same commit. `AccentColor` generates `Color.accent` as well as `Color.accentColor`.
  Glass: compiled for iOS 18 and 26, Debug and Release; not yet seen on screen, since nothing uses the
  modifiers — check the iOS 18.6 fallback on the simulator when the first screen uses them. Review:
  `swiftui-pro` no findings; SOLID / clean code no findings (the modifiers are unused until Feature 3
  by design). Size 634 is over the cap from the format, not the code: ~400 lines are the eight
  colorset JSON files and ~250 the new spec, plan and `docs/plan.md`; the Swift is ~55 lines. Kept as
  one branch.
- CL-9 (2026-11-21): PR #8 was merged, so CL-9 starts from `main` and its PR targets `main`. The
  `Tab` initializer that takes a `LocalizedStringResource` title is iOS 26-only, so the tabs keep the
  `Tab(value:content:label:)` form with a `Label` holding `Text(.tab…Title)`. Launched on the iPhone 16
  simulator (iOS 26): light, dark and Ukrainian (`-AppleLanguages (uk)`) all show three tabs with
  Today selected and the token colours. The iOS 18 glass fallback is still unseen — nothing uses
  `.glassSurface` yet. Review: `swiftui-pro` — `value: AppTab.today` shortened to `value: .today`,
  nothing else. SOLID / clean code: `AppTab` only serves `RootView` → a private supporting type in
  `RootView.swift` instead of its own file (deviation from the plan's file list). Kept: the three
  placeholder screens repeat the same `NavigationStack` + background + title; each is replaced by
  its feature's real screen, so a shared placeholder would be dead code then.

## Feature 3 — Apartments (done)

Plan: `docs/superpowers/plans/2026-11-21-apartments.md` · Spec: `docs/superpowers/specs/2026-11-21-apartments-design.md`

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 10 | `feature/CL-10-apartment-delete-name-order` | `main` | 1–3 | 298 code (+ spec and plan) | merged (PR #10) | done — concurrency clean; SOLID: 1 fix (below) |
| 11 | `feature/CL-11-apartment-view-models` | `main` | 4–5 | 386 | merged (PR #11) | done — concurrency clean; SwiftUI clean; SOLID: 2 fixes (below) |
| 13 | `feature/CL-13-apartment-form-view-model` | `main` | 6 | 310 | merged (PR #12) | done — concurrency clean; SwiftUI: 1 fix; SOLID: 2 fixes (below) |
| 12 | `feature/CL-12-apartments-screen` | `main` | 7–11 | 810 (530 Swift + 280 catalog JSON; end of feature) | merged (PR #13) | done — SwiftUI: 2 fixes; SOLID: 1 fix; rework review: 1 fix (below) |

Notes for the sessions:

- Plan review (2026-11-21), before code: `swiftui-pro` — alerts bind to settable flags
  (`isConfirmingDeletion`, `isShowingError`), not optionals; `swift-concurrency-pro` — clear the
  pending deletion before its `await`, refuse a second `save()` while one runs. Details and what was
  kept are at the end of the plan file.

- Brainstorming (2026-11-21): no archive — an apartment is deleted (history is safe: entries keep
  snapshots); no manual order — apartments sort by name (digit-only names numerically first, then the
  rest), and the report uses the same order; the form is a half-height sheet; delete is a confirmed
  swipe only; an empty state with an add button; no Settings button until Feature 9.
- CL-10 (2026-11-21): built as planned. Deviations: `updatesTheEditableFields` read the list's
  `.first`, but the renamed `100A` now sorts after `101` (digit-only names first) → it finds the
  apartment by id; the `WorkDayPlanningTests` copy tests' archived `205` became a plain fixture.
  Concurrency review: no findings (no new tasks or streams; `delete` has no `await` between fetch and
  delete). SOLID / clean code: the name-sort closure was repeated in both repositories and the report
  → `ApartmentNameOrder.sorted(_:by:)`, test-first. Size: 298 changed lines of code and tests; the
  rest of the diff is the feature spec and plan (and the deleted design-system spec). An existing
  simulator store from before this branch has the old `SchemaV1`: delete the app once.
- CL-11 (2026-11-21): PR #10 was merged, so CL-11 starts from `main` and its PR targets `main`. All
  three tasks came to 701 lines (245 code, 365 tests, 92 catalog JSON) against a ~450 estimate → split
  by the user's decision: Task 6 (`ApartmentFormViewModel`) moved to the stacked `CL-13`, already
  built and committed there; CL-12 now stacks on CL-13. Deviations: `MoneyInput.parse` takes no
  locale (it accepts `,` and `.` whatever the locale, as the plan's interface says; the spec's
  `locale:` there is dropped); the parse tests add non-ASCII digits and a whole part that overflows
  when multiplied by 100. The "once" tests (`confirmsADeletionOnce`, CL-13's `savesOnce`) passed
  trivially against `FakeApartmentRepository`, which never suspends, so the second call ran after
  the first had finished → `YieldingApartmentRepository` in `CleanLogTests/Support/` yields before
  each write. Mutation-checked: moving the `pendingDeletion` clear after the `await` makes
  `confirmsADeletionOnce` fail. Concurrency review: no findings (main-actor `for await` ended by
  `.task`'s cancellation, state cleared before the only `await`). SwiftUI review: no findings
  (`ApartmentSheet`'s `UUID?` id serves `.sheet(item:)`; the alerts bind to the settable flags).
  SOLID / clean code: `isConfirmingDeletion`'s setter repeated `cancelDeletion()` → calls it; three
  tests repeated the start-observe-and-wait boilerplate → `observing(_:_:)` takes the view model.
  Kept: `MoneyInput.string` of a negative amount prints a wrong fraction, but a price is never
  negative (the draft refuses it). Merged up into CL-13 (test file conflict resolved; builds, its
  tests not run yet).
- CL-13 (2026-11-21): PR #11 was merged, so `main` was merged in and CL-13's PR targets `main`.
  Built in the CL-11 session (Task 6); this session ran its tests and the review. Concurrency
  review: no findings (`isSaving` is set before the only `await` and cleared in `defer`; `savesOnce`
  overlaps two saves through `YieldingApartmentRepository`). SwiftUI review: `filter { $0 }.count`
  in `savesOnce` → `count(where:)`. SOLID / clean code: the form's `init` declared its three
  parameters on one line → one per line; `makeFormViewModel(for:)` repeated the same three-argument
  construction in both `switch` branches → `ApartmentSheet.apartment` (which `id` now reuses) and
  one call. Kept: the `enablesSaveForAValidForm` argument tuples stay packed — they read as a table.
  Decision (user, 2026-11-21): **no Polish** — the app ships Ukrainian and English only. Removed on
  this branch: the `pl` strings from the catalog, `pl` from the project's known regions, and Polish
  from `code-style.md`, both specs and the apartments plan (CL-12's string list is uk / en).
- CL-12 (2026-11-21): PR #12 was merged, so CL-12 starts from `main` and its PR targets `main`.
  Built as planned. Deviations: `MoneyFormat.currencySymbol` became internal so the price field's
  «zł» suffix reuses it instead of a second literal; the «Окремо у звіті» toggle is tinted
  `Color.accent` (a system toggle stays green otherwise); the row's name and badge stack vertically
  at accessibility text sizes (`AnyLayout`). Seen on the iPhone 16 simulator (iOS 26) through a
  temporary, uncommitted tweak (Apartments tab selected, the fake repository with the preview
  template, the sheet preset to new / edit): the empty state, the list, the new and edit sheets in
  light, dark, Ukrainian and the largest Dynamic Type size. **Not seen**: the swipe, the delete
  alert, typing, a duplicate-name error and a real save — `simctl` cannot tap and no tap tool is
  installed; check them by hand on the simulator or a device. The iOS 18 glass fallback is still
  unseen (no iOS 18 runtime). SwiftUI review: the save button's `Task { if await save() … }` moved
  into `save()`; buttons that wrap one call take it as `action:`. SOLID / clean code: the form's
  `body` passed ~40 lines with the access code row inline while name and price were extracted →
  `AccessCodeField`. Kept: the action-less error alert appears in both views (two view models, one
  line each); a row reads name, badge, price to VoiceOver (layout order), not the spec's name,
  price, badge. Size: the Swift is 364 lines; the rest is the string catalog's JSON (16 keys × uk/en),
  kept as one branch like CL-8.
- CL-12 rework (2026-11-21, same session): the user reviewed the screen and asked for a big
  «Додати квартиру» button, the form as a centered popup over a blurred screen, and no form title.
  Brainstormed (approach A: a full-screen cover without the system slide, own fade and scale; spec
  section "Revision after the first screen review"), planned as Tasks 9–11, built inline. Task 9:
  `ApartmentFormViewModel.title` → `isAdding`, test-first; the `apartments.form.title.new` key gone.
  Task 10: the toolbar `+` and the empty state's button replaced by one pinned full-width button
  (`apartments.action.add` is now «Додати квартиру», `apartments.empty.action` gone); its text stops
  growing at the first accessibility size (uncapped it covered a third of the list). Task 11: the
  popup; deviations — `.ultraThinMaterial` backdrop (thin hid the screen entirely), a
  `FormRowStyle` stacks label over field at accessibility sizes (`LabeledContent` does not outside a
  `Form`), scoped to the text fields because a `Toggle` renders through `LabeledContent` too, and
  the ink colour scoped to the rows (it darkened the Save label). Seen on the simulator (temporary
  tweak): empty state, list, new and edit popups in light, dark, Ukrainian and the largest text.
  Still not seen: typing with the keyboard up, a real save, swipe-delete. Rework review
  (self-review): the card stayed tappable while animating closed, so a second Save could re-add and
  flash the duplicate-name error → `allowsHitTesting(isShown)`. Kept: `ApartmentSheet` keeps its name
  for the cover route; the no-slide transaction appears three times (one call each). **Next branch:
  the canvas's gradient background for every screen** (the user's decision; not in this PR).
- Feature 3 is done: PR CL-12 merged 2026-11-22; its plan file is deleted on CL-14 (the spec stays).
- **For Feature 4:** «Як учора» must not copy apartments deleted since that day — filter the copy by
  the current template.

## Screen background (between Feature 3 and 4)

Done: PR CL-14 merged 2026-11-22; its plan file is deleted on CL-16 (the spec stays).

Spec: `docs/superpowers/specs/2026-11-22-screen-background-design.md`

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 14 | `feature/CL-14-gradient-background` | `main` | 1–3 | 271 code (end of the work) | merged (PR #14) | done — SwiftUI clean; SOLID: 2 fixes (below) |

Notes for the sessions:

- Brainstorming (2026-11-22): the canvas "gradient" is a `#E6F7F8` fill with two blurred circles;
  the user chose the canvas's per-screen placement (not one shared layout) and approach 1 (one
  `.screenBackground(_:)` modifier, circles per screen) over a `MeshGradient` or images. Dark circle
  colours are a proposal. Feature 3's plan file is deleted on this branch.
- CL-14 (2026-11-22): built as planned, blur kept at the canvas's 70. Seen on the iPhone 16
  simulator (iOS 26) through a temporary, uncommitted tweak (launch arguments pick the tab, the fake
  repository with the preview template): Today, Statistics and Apartments in light and dark, the
  list over its circles. **Not seen**: the form popup over the new background and the keyboard —
  both need a tap. Review: `swiftui-pro` no findings (plan review had moved `.ignoresSafeArea()` onto
  the `GeometryReader`, so `proxy.size` is the whole screen and the keyboard does not shrink it).
  Fresh reviewer (Opus): no Critical or Important; fixed two rule breaks — the `Tone.color`
  extension lived away from its type → a private `color(for:)` in the modifier; the new rule said
  "never `Color.background`" though previews use it → "a screen never paints it itself (a
  `#Preview` may)". Kept: `ForEach(circles, id: \.self)` (two equal circles would draw the same
  pixels); the modifier's preview repeats Today's circles. `project.pbxproj` shows Xcode
  reordering its build phases when the project is open — left uncommitted. Size 271 lines of code
  and tests: under 300 as the natural end of this work.

## Apartments fixes after use (2026-11-22)

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 15 | `feature/CL-15-apartment-deletion` | `main` | — (bug fix + copy) | 186 | merged (PR #15) | done — SwiftUI: 1 kept exception; SOLID clean (below) |

- CL-15 (2026-11-22), from the user trying the app: **deleting never happened.** The alert's
  dismissal reset `isConfirmingDeletion`, which cleared `pendingDeletion` before the button's `Task`
  ran `confirmDeletion()`, so the guard returned; the swipe button's `role: .destructive` meanwhile
  hid the row by itself. Fix: `confirmDeletion(of:)` takes the row the alert presents; the
  once-guard is a set of IDs in progress; new test `deletesTheConfirmedRowAfterTheAlertDismisses`.
  Then the real deletion crashed the `List` ("attempt to delete item 0 … only contains 0 items"):
  the destructive role had already removed the row → the swipe button has no role and a new
  `Destructive` colour token (system red, added to `code-style.md`). User's copy and layout
  changes, recorded in the apartments spec: the empty state's button sits under its title (own
  stack, 32 pt gap, icon on an `AccentSoft` circle — `ContentUnavailableView`'s action gap is
  fixed, so the `swiftui-pro` "prefer `ContentUnavailableView`" rule is a kept exception); title
  «Поки ти не маєш жодної квартири»; name field «Номер квартири» with a «Напр. 106» placeholder;
  the new-price footnote is gone. Seen by the user in the simulator; tests, build and lint green.
- **Open offer:** a grey line under the empty state's title telling what to do — the user has not
  decided.

## Feature 4 — Today

Plan: `docs/superpowers/plans/2026-11-22-today.md` · Spec: `docs/superpowers/specs/2026-11-22-today-design.md`

Done: CL-20 merged as PR #28; the plan file was deleted on CL-28.

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 21 | `feature/CL-21-today-spec-plan` | `main` | — (spec, plan, design) | 912 (docs only) | merged (PR #17) | — |
| 16 | `feature/CL-16-today-domain` | CL-21 | 1–4 | 405 | merged (PR #16) | done — concurrency clean; SOLID: 1 fix (below) |
| 17 | `feature/CL-17-day-view-model` | `main` | 5, 6 (header, rows) | 500 | merged (PR #18) | done — concurrency clean; SwiftUI clean; SOLID: 1 fix (below) |
| 22 | `feature/CL-22-day-summaries` | CL-17 | 6 (summaries, «Як учора») | 325 | merged (PRs #19, #21) | done — concurrency clean; SwiftUI clean; SOLID: 1 fix (below) |
| 18 | `feature/CL-18-day-actions` | CL-22 | 7–8 | 452 | merged (PR #20) | done — concurrency clean; SwiftUI clean; SOLID: 3 fixes (below) |
| 23 | `feature/CL-23-day-timer-actions` | `main` | 9 | 137 | merged (PR #22) | done — concurrency clean; SwiftUI clean; SOLID clean (below) |
| 19 | `feature/CL-19-today-screen` | `main` | 10 | 387 | merged (PR #23) | done — concurrency: 1 fix; SwiftUI: 1 fix; SOLID: 2 fixes (below) |
| 24 | `feature/CL-24-timer-card` | `main` | 11 | 392 | merged (PR #25) | done — concurrency clean; SwiftUI clean; conventions: 2 fixes (below) |
| 25 | `feature/CL-25-day-list` | `main` | 12 (the list) | 330 | merged (PR #26) | done — concurrency clean; SwiftUI: 1 fix; SOLID clean (below) |
| 27 | `feature/CL-27-day-summaries` | `main` | 12 (the summary cards) | 256 | merged (PR #27) | done — SwiftUI: 1 fix; SOLID clean (below) |
| 20 | `feature/CL-20-today-states` | `main` | 13–14 | 531 (end of feature) | merged (PR #28) | done — concurrency, SwiftUI, SOLID clean (below) |

Notes for the sessions:

- Brainstorming (2026-11-22): Today ships **without** the Day plan button, the floating add button and
  the calendar button — they come with their sheets in Features 5 and 6, so a fresh install cannot plan
  its first day until Feature 5 (hand the app to the user after it). «Стоп» finishes at once and
  «Продовжити» restarts. User's timer rules: **the last tick stops the timer**; **a timer still open
  after midnight drops all of its day's time** (the cleaner never works past midnight). One
  `DayViewModel` per shown day (`.id`). Claude's calls (accepted): «Як учора» copies at current template
  prices and hides when nothing remains; the overrun drop is a stored write (`isTimeDropped`), so
  Statistics and Report need no rule of their own.
- Plan review (2026-11-22, before code): `swiftui-pro` — one `List` for swipe actions, `TodaySummary`
  and `DurationParts` structs, a work-free `DayView.init`; `swift-concurrency-pro` — the copy source
  fetched once with the flag set before the `await`; the midnight refresh sleeps to the next day
  instead of iterating `NotificationCenter.notifications`. Details at the end of the plan file.
- `SchemaV1` gains `isTimeDropped` in place (no TestFlight yet): delete the simulator app once after
  CL-16.

- CL-16 (2026-11-22), built as planned with these calls: the last-tick auto-finish is
  `(try? finishingTimer(...)) ?? self` after the today/all-ticked guard (it throws exactly for the
  idle/finished "leave it" cases); `WorkDay.hasOpenSession` is new and shared by the drop rule and both
  repositories; `DayFormat.month` needs no verbatim `LLLL` (a month-only skeleton is already the
  standalone form); the en_US time has ICU's narrow no-break space (`7:40\u{202F}AM`). Review:
  `swift-concurrency-pro` clean; SOLID — `timeSpan` named the zipped sessions `previous`/`next`
  instead of `pair.0`/`pair.1`. Minor left: `DayKey(year:month:day: 1)` for a month's first day is
  spelled in `MonthKey` twice and in `DayFormat.month` — a `MonthKey.firstDay` would join them.

- The size rule counts the whole `git diff --shortstat <base>...HEAD`, docs included. CL-16 first
  measured 1107+/204− because the spec and plan sat at its bottom; they moved to CL-21 (a branch at
  the planning commit, no history rewritten) and CL-16 now stacks on it. A feature's spec and plan go
  on their own branch from now on, never at the bottom of the first code branch.

- CL-17 (2026-11-23): Tasks 5–6 were 792 lines (a catalog key is 25–40 JSON lines) → split: sums and
  the copy offer to CL-22, Task 7 to CL-18, Task 9 to CL-23 (this table overrides the plan file's).
  `header`/`kind` are `let`; `String(localized:locale:)` also picks the language. Review: concurrency,
  SwiftUI clean; SOLID 1 fix. CL-18: `DayTimer.past` needs no `isTimeDropped` beside `droppedNote`.

- CL-22 (2026-11-23): summaries and the copy offer as planned. Review: concurrency clean (the copy
  source is fetched once, the flag set before the `await`); no views, SwiftUI clean; SOLID —
  `DaySummary` formatted the earned and planned sums twice each, now once. Minor left: on today the
  first day emission can render the month card with 0 zł before the month stream's first value — one
  frame at most; make `monthDays` optional if it shows on a device.

- CL-18 (2026-11-23): Tasks 7–8 as planned, with these calls: the tick is `setCleaned(_:to:)`, not the
  plan's `toggle(_:)` (the naming rule; the row passes the value it wants, so a double tap cannot
  undo itself); `DayTimer.past` carries no `isTimeDropped` (the view reads `droppedNote`); a failed
  overrun sweep shows the same «Не вдалося зберегти зміну» as a failed tap — never swallowed; the
  copy-source read still only logs. `FailingWorkDayRepository` in `CleanLogTests/Support/` throws on
  every `update`. Review: concurrency clean (each change runs on the stored day handed to the
  closure, `now()` read before the `await`, the sweep ends before the streams start); SwiftUI clean (no
  views); SOLID — `fail` → `showSaveError`, dropped capture lists on non-escaping closures,
  `DayTimer.init` formats the total and span only for the cases that show them (and 3+ argument calls
  one per line). Minor left: `DaySummary` still has a 3-argument `DayFormat.month(…)` on one line.

- CL-23 (2026-11-24): based on `main`, not CL-18 — PRs #20 and #21 had merged CL-17/22/18 into `main`.
  Task 9 as planned: `startTimer`/`pauseTimer`/`finishTimer` (start also resumes and restarts after
  «Стоп»), `setManualDuration(_:)`/`resetManualDuration()`, `manualDurationParts` rounded down to
  minutes; `DurationParts` lives in `Features/Today/` with `init(roundingDown:)` and `duration`. A refused
  timer change (pause while idle) shows «Не вдалося зберегти зміну». Tests drive time through
  `TestClock` in `CleanLogTests/Support/`. 137 lines, under the 300 floor: the split was fixed when CL-18
  was cut, and joining UI Task 10 would break the logic/UI rule. Review: concurrency clean (`now()` read
  before every `await`, each change on the stored day); SwiftUI clean (no views); SOLID clean.

- CL-19 (2026-11-24): based on `main` (CL-23 merged as PR #22). Tasks 10–12 measured ~900 lines (each
  task's catalog keys are 50–120 JSON lines) → split: Task 10 stays here, Task 11 (the timer card) went
  to CL-24, Task 12 (sums and the list) to CL-25. Calls: `TodayView` hides the navigation bar and draws
  its own header; `DayView` is one `List` whose header cards are clear rows (`CardRow`), ready for
  CL-25's apartment section; the save-error alert is already on `DayView` (the plan had it in Task 14);
  the «Сьогодні» glass button sits in the header now (Task 14 listed it); `AppDependencies.preview`
  takes repositories. Checked on the iPhone 16 simulator: today's header renders under the backdrop
  (taps could not be driven from the CLI — no accessibility access for scripted clicks). Review:
  concurrency — the midnight `.task(id:)` slept once per day, so a wake-up that found the same day (the
  clock set back) never re-armed it → one `.task` loops `advanceAtEachMidnight()`; SwiftUI — that logic
  moved out of `.task` into a method; SOLID — the step actions are named methods (`stepBack`,
  `stepForward`), the preview fixture states `isReportedSeparately` instead of deriving it from the
  price. Minor left: `DayView.init` builds a `DayViewModel` (with the header's date formatting) on every
  `TodayView` body run — rare (selection and scene-phase changes), the convention's pattern.

- CL-24 (2026-11-24): Task 11 as planned; «Змінити» and its `today.timer.edit` key wait for Task 14 with
  the picker sheet, so no key ships unused. Base is `main` (CL-19 merged as PR #23). Review: concurrency
  clean (each button's `Task {}` inherits the main actor and calls a non-throwing intent that shows its
  own error; the `TimelineView` exists only while running); SwiftUI clean; conventions — at
  accessibility text sizes the clock and the two scaled 52 pt buttons did not fit one row, so the card
  stacks its controls under the text (`AnyLayout`, as in `ApartmentRowView`); `Color.accentColor` →
  the generated `Color.accent`. Minor left: `ApartmentsView` still uses `Color.accentColor`; a fast
  double tap on «Почати»/«Продовжити» can land on «Стоп», which takes its place — undone with one tap
  (spec decision 2), revisit if it happens on a device.

- CL-25 (2026-11-24): based on `main` (CL-24 merged as PR #25). Task 12 measured 556 lines → split: the
  apartment list stays here, the summary cards went to CL-27 (232 lines, under the 300 floor: joining
  CL-20 would put that branch past 500). The «окремо» badge moved from Apartments to `UICommons/Badge`
  with the text as a parameter — each feature keeps its own key, since Apartments says «окремо у
  звіті». The checkmark is drawn in `Card` on `Accent` (white would fail on the dark accent); rows get
  explicit 4/18 insets for the canvas' 58 pt height. Checked on the iPhone 16 simulator with the preview
  fakes (swipes and taps could not be driven from the CLI). Review: concurrency clean (the two button
  `Task {}`s as in CL-24); SwiftUI — the tick and remove actions are named methods on `DayListRow`; the
  skill's one-type-per-file rule yields to the convention's supporting-type rule; SOLID clean.
  Open: the spec's «ще немає квартир» text on today's card with nothing planned waits for CL-20's
  empty state, which may cover that case.

- CL-27 (2026-11-24): based on `main` after CL-25 merged (PR #26; merged in, never rebased). The today
  card pair (today with progress, the month) stacks at accessibility sizes (`AnyLayout`); past and
  future days show one card. Review: no concurrency code; SwiftUI — the single card wrote its title
  styling twice in its `ViewThatFits`, now `SummaryTitle`; SOLID clean (no logic or formatter in the
  view). Build, full tests, lint green.

- CL-20 (2026-11-24): based on `main` (CL-27 merged as PR #27). Tasks 13–14 plus the spec's «ще немає
  квартир»: `TodaySummary.planned` is nil when nothing is planned, and the today card then shows that
  caption instead of «з 0 zł» and the bar (closes CL-25's open point). The empty day is a `Card` with the
  icon on an `AccentSoft` circle, the title and a bordered «Як учора» button; the canvas' grey
  description and «Додати квартири» come with Feature 5 (both are about adding apartments). The
  past day's timer card has a glass «Змінити» capsule → `ManualDurationSheet` (one
  `.sheet(isPresented:)` on `DayView`, wheels prefilled from `manualDurationParts`, Save / Cancel in
  the toolbar). Calls: the hours wheel is 0…23, not the plan's 0…16, so a long day's real time always
  fits the wheel without clamping; «Скинути» shows only when a manual time is set
  (`canResetManualDuration`, tested) — no button that does nothing. Checked on the iPhone 16 simulator
  with fixture data swapped in temporarily (empty today with the copy offer, a past day, the sheet).
  Size 517 + this note, over 500: the user chose to keep it whole as the feature's last branch (a split
  would leave a 169-line branch under the floor; ~170 lines are catalog JSON). Review: concurrency — the
  button `Task {}`s as in CL-24, the sheet dismisses before its write so a save error's alert can show
  on `DayView`; SwiftUI clean; SOLID clean. Full tests, Debug and Release builds, lint green.

## Feature 5 — Day plan (done)

The plan file was deleted once the feature merged (CL-31); the notes below stay as the record. Spec:
`docs/superpowers/specs/2026-11-24-day-plan-design.md`.

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 28 | `feature/CL-28-day-plan-spec` | `main` | — (spec, plan; deletes the Today plan) | 952 (docs only: 473 new, 483 the deleted Today plan) | merged (PR #29) | plan review done (in the plan) |
| 29 | `feature/CL-29-day-plan-logic` | CL-28 | 1–3 | 889 (277 of it string-catalog JSON) | merged (PR #30) | done — concurrency: 1 fix; SwiftUI: 1 fix; SOLID: 2 fixes (below) |
| 30 | `feature/CL-30-day-plan-sheet` | `main` (CL-29 merged in) | 4–5 | 480 with this note | merged (PR #31) | done — SwiftUI: 1 fix; SOLID: clean, 1 open point (below) |

Notes for the sessions:

- CL-28 (2026-11-24): brainstorm decisions (all in the spec): no floating add button (dropped from the
  product; a «+ Додати квартиру» row ends the list on every day instead); the sheet shows only apartments
  not on the day and never removes; «Нова» opens the shared apartment form as a full-screen cover and
  comes back selected; adding to a today whose timer stopped by itself leaves the timer finished (an
  auto-start could run past midnight and lose the day's time). Builder check: 2 questions, one settled
  by Claude (the form is not pushed), one by the user (the timer). Size 952, docs only: the user kept it
  one branch, as CL-21 (2026-11-24). Execution: native, one fresh session per branch.
- CL-29 (2026-11-24): Tasks 1–3 as planned. Size 889 with the docs, over the cap: 277 lines are the 14 catalog keys
  (xcstrings JSON, about 20 lines a key) and no split gets Task 2 under 500, so the user kept it one
  branch. Review — `swift-concurrency-pro`: `GatedWorkDayRepository` gated `update` on one
  `AsyncStream`, so a regressed double confirm would trap on a second consumer instead of failing the
  test; now one checked continuation per waiter. `swiftui-pro`: the search uses
  `localizedStandardContains`. SOLID / clean code: `toggle(_:)` → `toggleSelection(of:)` (the naming
  rule), and the «Нова» callback selects instead of toggling; the `stored(_:in:)` helper copied into both
  view-model suites → `WorkDayRepository.stored(_:)` in `CleanLogTests/Support/`. Build, full test run,
  lint green.

- CL-30 (2026-11-24): Tasks 4–5 as planned. Tile numbers from the `AddSheet` artboard (74 pt high, radius 22,
  gap 10, three columns at default size through an adaptive grid with a 96 pt minimum scaled with
  `.title3`). On the iPhone 16 simulator (fixtures swapped in temporarily) the plain iOS 26 sheet is white,
  so the `Card` tiles vanished: the sheet now sets its own `.screenBackground` with the artboard's two
  circles. At the largest accessibility size the grid is one column, nothing clips; the confirm button
  wrapped to two lines and is capped at `accessibility1` like the day screen's copy button. The toolbar ✓
  stays on both iOS versions (its label is the confirm title). Review: `swiftui-pro` — the sheet's `body`
  was ~60 lines with an inline tile closure, now `DayPlanGrid` with a named toggle; SOLID clean. **Open
  point for the user:** a selected tile's text is `Color.card` on `AccentColor` (white in light, dark
  `#1A2124` on `#3FC2B7` in dark, where white would fail contrast); that gives `Card` a second role. The
  alternative inside the token table is an `AccentSoft` fill with accent text, which departs from the
  artboard's solid fill. Not checked visually: a selected tile, dark mode. Build, full tests, lint green. Resolved in CL-31 (the
user chose a new token): `OnAccent` (`#FFFFFF` / `#1A2124`) for text and glyphs on an accent fill, used by
the selected tile and the day row's checkmark.

## Feature 6 — Calendar

Plan: `docs/superpowers/plans/2026-11-24-calendar.md` · Spec: `docs/superpowers/specs/2026-11-24-calendar-design.md`

Done: PR #37 merged 2026-11-25. The plan file was deleted in CL-36.

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 31 | `feature/CL-31-calendar-spec` | `main` | — (spec, plan, the `OnAccent` token; deletes the Day plan plan) | 805 (docs, 277 of it the deleted plan; the user kept it one branch) | merged (PR #32) | plan review done (in the plan) |
| 32 | `feature/CL-32-calendar-logic` | `main` | 1–3 | 473 | merged (PR #33) | done — concurrency clean; SOLID: 1 fix (below) |
| 34 | `feature/CL-34-calendar-day-card` | `main` (`main` merged in) | 4 | 401 | merged (PR #35; PR #34 merged into CL-32 after CL-32 merged) | done — concurrency clean; SOLID clean (below) |
| 33 | `feature/CL-33-calendar-sheet` | CL-34 | 5 | 690 (over the cap, below) | merged into CL-34 (PR #36); reached `main` with PR #35 | done — `swiftui-pro`: 3 fixes; SOLID: 1 fix (below) |
| 35 | `feature/CL-35-calendar-button` | `main` | 6 | 111 (the natural end of the feature) | merged (PR #37) | done — `swiftui-pro`: 1 fix; SOLID clean (below) |

Notes for the sessions:

- CL-31 (2026-11-24): brainstorm decisions (all in the spec): the grid shows earnings only on days that
  earned (the user's option B — planned days are not marked); the card says «4 квартири · 140 zł», «5
  квартир» for a plan, «вихідний» otherwise; quick buttons select, never open; the calendar button is in
  the header on every day; our own SwiftUI grid, not `UICalendarView`. The sheet is presented by
  `TodayView` (`DayView` is rebuilt per day). Builder check done in-session: no questions for the user.
  Execution: native, one fresh session per branch.
- CL-32 (2026-11-24): Tasks 1–3; 432 lines after Task 3, so Task 4 (seven catalog keys, two of them
  plurals) moved to CL-34 and CL-33 now stacks on CL-34. Deviations, all in the plan file: the Ukrainian
  month title is Foundation's «Листопад 2026\u{202F}р.» (pinned, spec updated); `DayFormat.dayNumber` added
  for the cell number; `String(localized:locale:)` moved to `Formatting/` (`nonisolated`), as Calendar is its
  third feature. Review: concurrency clean (the `where month == shownMonth` guard and the assignment run
  with no suspension between them); SOLID: the earnings map moved into a named `earnings(in:)` that keeps
  the first record for a day instead of trapping on a duplicate (possible once sync exists).
  `TodaySelection.show(_:)` has no caller until CL-33 (planned). Build, full tests, lint green.
- CL-34 (2026-11-24): Task 4. Deviations, in the plan file: `card` and `quickPicks` are computed, not
  stored — `card` builds from the last observed `WorkDay` only while its day is still `selected`, so right
  after a new selection it is `nil` until that day's stream yields (no stale summary under a new date;
  pinned by `cardWaitsForTheNewlySelectedDay`); an extra test pins the three quick picks' days, titles and
  selection. Seven catalog keys (`calendar.card.dayOff/earned/planned/today`, `calendar.quick.*`; the plan
  said six). Review: concurrency clean (`observeSelectedDay()` mirrors `observeMonth()`: the `where` guard and
  the assignment run with no suspension between them); SOLID clean. Build, full tests, lint green.
- CL-33 (2026-11-24): Task 5. Size 690 with the docs (647 code): the sheet alone is 420 lines, the branch 605 after Task 5,
  so Task 6 moved to CL-35. Deviations: `StepButton` left `DayHeaderView` for `UICommons/`, and the ✕ is a
  new `UICommons/GlassIconButton` (Task 6's calendar button uses both); the card is pinned in a bottom
  `safeAreaInset` (the artboard's card sits at the bottom) and keeps its height while `card` is `nil` by
  laying out an invisible placeholder; the grid is a SwiftUI `Grid`. On the iPhone 16 simulator (the app
  temporarily launched into the sheet with the preview fake), light and dark match the artboard. At
  `accessibility5` the month title broke per syllable and the quick picks filled the screen: the header,
  quick picks, grid and card are capped at `accessibility1`, and the cells hide their amount at
  accessibility sizes (still in the label). The pinned card then covers the lower weeks, which scroll
  under it. Review — `swiftui-pro`: three computed `some View` properties became structs
  (`CalendarQuickPickButtons`, `CalendarDayCardDate`, `CalendarDayCardSummary`) and the today ring is a
  colour ternary instead of an `if` in the overlay. SOLID: «Відкрити день» copied DayPlan's confirm button
  style → `UICommons/prominentActionStyle()`, used by both. Build, 227 tests, lint green.

- CL-35 (2026-11-25): Task 6. The header's trailing side is an `HStack` of «Сьогодні» (past and future
  days) and `GlassIconButton` with `calendar`; `TodayView` presents the sheet on the `NavigationStack`,
  outside the per-day `.id(selection)` view, and «Відкрити день» calls `selection.show(_:)`. One key,
  `today.header.calendar`. Review — `swiftui-pro`: `DayHeaderView.body` reached 44 lines, so «Сьогодні»
  became a private `ShowTodayButton` struct in the same file; the sheet first sat after `.id(selection)` and
  moved to the stack, as the plan says. SOLID clean. On the iPhone 16 simulator the header shows the button
  on today and beside «Сьогодні» on a past day (the app launched temporarily on yesterday); the
  tap-through flow (open, pick a day, open it, back with «Сьогодні») was **not** driven, as there is no tap
  tool in the session — check it by hand. Found, not fixed (also on `main`): a lighter rectangle the size of
  the trailing group sits behind the header's glass buttons, the glass drawn inside a `List` row; it is
  now visible on today too. Follow-up, own branch. Build, full tests, lint green.

## Feature 7 — Statistics

Plan: `docs/superpowers/plans/2026-11-25-statistics.md` · Spec: `docs/superpowers/specs/2026-11-25-statistics-design.md`

**NEXT session:** once PR for CL-36 is open, `feature/CL-37-statistics-logic` (Tasks 1–3), stacked on CL-36 —
or on `main` if CL-36 has merged (check on GitHub first). Execution: native, one fresh session per branch.

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 36 | `feature/CL-36-statistics-spec` | `main` | — (spec, plan, product spec; deletes the Calendar plan) | 847 (docs, 301 of it the deleted plan, as in CL-31) | built | plan review done (in the plan) |
| 37 | `feature/CL-37-statistics-logic` | CL-36 | 1–3 | — | next | `SOLID` |
| 38 | `feature/CL-38-statistics-summary` | CL-37 | 4 | — | planned | `SOLID` |
| 39 | `feature/CL-39-statistics-view-model` | CL-38 | 5 | — | planned | `swift-concurrency-pro` + SOLID |
| 40 | `feature/CL-40-statistics-screen` | CL-39 | 6 | — | planned | `swiftui-pro` + SOLID |

Notes for the sessions:

- CL-36 (2026-11-25): brainstorm decisions (all in the spec): the change badge shows only on a finished month
  (option C) and hides when either month earned zero; a day's time counts only once its work is over (manual,
  past day, or today finished) — no per-minute refresh, so «За годину» does not move while she works; a past
  day with an undropped open session counts nothing; › stops at the current month; «Звіт» moves to Feature 8.
  Approach: two `days(in:)` observations (shown and previous month) in the view model, no repository change.
  Builder check: one question for the user (the zero-earnings badge → hidden), two Claude's calls. Checked
  against Foundation in-session: «62 год, 15 хв» (with a comma), «0 год», the genitive «жовтня» from
  `\(month: .wide)` in a verbatim style, «2 016 zł» grouped with a no-break space.

Next free branch number: **CL-41** (CL-16…40 are used or reserved above; CL-26 is the iCloud spec, merged as PR #24).

## Roadmap (v1)

Each feature: brainstorm → plan (split into 300–500-line branches, written here) → plan review →
branches as above.

1. Foundation — done.
2. Design system — done.
3. Apartments (template) — done.
4. Today — done.
5. Day plan — done.
6. Calendar — done.
   Follow-up: the rectangle behind the day header's glass buttons (CL-35 notes).
7. Statistics — in progress (CL-36…40). Logic, then UI.
8. Report and WhatsApp. Logic, then UI.
9. Settings and reminders. Logic, then UI.
10. iCloud sync (spec: "iCloud sync"): private CloudKit database, remote-change refresh, duplicate
    merging, the iCloud status line in Settings. Logic, then UI.
11. First launch, app icon, Bundle ID, privacy policy, TestFlight.

Later: Live Activity, home-screen widget, PDF/CSV export.
