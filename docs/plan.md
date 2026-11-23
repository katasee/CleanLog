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

**NEXT session:** `git switch feature/CL-22-day-summaries` (local, built): review from step 4; PR base CL-17.

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 21 | `feature/CL-21-today-spec-plan` | `main` | — (spec, plan, design) | 912 (docs only) | merged (PR #17) | — |
| 16 | `feature/CL-16-today-domain` | CL-21 | 1–4 | 405 | merged (PR #16) | done — concurrency clean; SOLID: 1 fix (below) |
| 17 | `feature/CL-17-day-view-model` | `main` | 5, 6 (header, rows) | 500 | PR #18 open | done — concurrency clean; SwiftUI clean; SOLID: 1 fix (below) |
| 22 | `feature/CL-22-day-summaries` | CL-17 | 6 (summaries, «Як учора») | see below | built, not reviewed | — |
| 18 | `feature/CL-18-day-actions` | CL-22 | 7–8 | ~470 est. | not started | — |
| 23 | `feature/CL-23-day-timer-actions` | CL-18 | 9 | ~250 est. | not started | — |
| 19 | `feature/CL-19-today-screen` | CL-23 | 10–12 | ~450 est. | not started | — |
| 20 | `feature/CL-20-today-states` | CL-19 | 13–14 | ~350 est. (end of feature) | not started | — |

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

Next free branch number: **CL-24** (CL-16…23 are used above).

## Roadmap (v1)

Each feature: brainstorm → plan (split into 300–500-line branches, written here) → plan review →
branches as above.

1. Foundation — done.
2. Design system — done.
3. Apartments (template) — done.
4. Today — ticks, timer, empty state, "as yesterday", past and future days. Logic, then UI. Planned (above).
5. Day plan sheet, and the floating add button beside the tab bar. Logic, then UI.
6. Calendar. Logic, then UI.
7. Statistics. Logic, then UI.
8. Report and WhatsApp. Logic, then UI.
9. Settings and reminders. Logic, then UI.
10. First launch, app icon, Bundle ID, privacy policy, TestFlight.

Later: Live Activity, home-screen widget, iCloud sync, PDF/CSV export.
