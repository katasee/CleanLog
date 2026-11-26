# iCloud Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The store syncs with her private CloudKit database, remote changes refresh every screen, offline
duplicates merge into one apartment / one day without losing a tick or a minute, and Settings shows whether the
data is synced.

**Architecture:** Pure merge rules over `Revision<Value>` (a domain value plus its `changedAt`) in
`Models/Sync/`; records gain `changedAt`, stamped by the repositories; `StoreDuplicateMerger` (`Persistence/`)
applies the rules to the store; `StoreSync` (`Persistence/`) runs the merge on start and on every
`NSPersistentStoreRemoteChange`, then re-yields both repositories' streams. `ModelContainerFactory` gains a
`ModelStorage` choice; the app uses `.iCloud`. Settings reads a `CloudAccount` protocol (`SystemCloudAccount` in
`App/` is the only CloudKit code).

**Tech Stack:** SwiftData with CloudKit mirroring, CloudKit (`CKContainer.accountStatus`), CoreData (the remote
change notification name only), SwiftUI, Swift Testing. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-11-26-icloud-sync-design.md` (product spec: iCloud sync).

## Global Constraints

- iOS 18.0+, Swift 6, default `MainActor` isolation; every type in `Models/` is `nonisolated`. Anything else
  `nonisolated` carries its reason in the commit message.
- `SwiftData` and `CoreData` only in `Persistence/` and `App/`; `CloudKit` only in `App/SystemCloudAccount.swift`.
- Container `iCloud.com.cleanlog`, Bundle ID `com.cleanlog`, tests `com.cleanlog.tests`, Team `78HWZYA4DR`.
- Records stay CloudKit-compatible: every new attribute defaulted (`changedAt = Date.distantPast`), no unique
  constraints. `SchemaV1` changes in place (start fresh, no TestFlight yet).
- A merge is deterministic: survivor = smallest `id.uuidString`; merged `changedAt` = latest of the copies.
- Copy (uk / en): header `settings.icloud.header` «iCloud» / "iCloud"; `settings.icloud.synced`
  «Синхронізовано з iCloud» / "Synced with iCloud"; `settings.icloud.local` «Зберігається лише на цьому телефоні» /
  "Kept on this phone only".
- Tests pin `now`, `Calendar` (`.warsaw`) and `Locale`; no sleeps (`eventually`, gates, manual streams).
- No comments in Swift; one argument per line for 3+ arguments; `swift-format lint --strict` clean.

## Review Focus

- A day planned on the new phone before the old data arrived → the old ticks survive the merge (Task 2 test
  `aTickInEitherCopyIsKept`).
- The timer run on both devices at once → the overlap is counted once (Task 2 test `overlappingSessionsFold`).
- A merged apartment whose removed copy is referenced by past entries → those entries point at the survivor, so
  Day plan does not offer it twice and Statistics counts it as one (Task 4 test `repointsEntriesOfRemovedCopies`).
- The merge's own save fires another remote change → the second pass finds nothing and does not save (Task 4 test
  `aCleanStoreIsNotSaved`).
- Duplicates "100" and " 100 " (spaces) or "6Piw" / "6piw" → one apartment (Task 1 test
  `namesMatchWithoutCaseAndSurroundingSpaces`).

## Branches

| CL | Branch | Base | Tasks | Manual step |
|---|---|---|---|---|
| 52 | `feature/CL-52-icloud-spec` | `main` | — (spec, this plan, product spec) | — |
| 53 | `feature/CL-53-merge-rules` | `main` | 1–2 | — |
| 54 | `feature/CL-54-store-merge` | CL-53 (or `main`) | 3–4 | delete the app after it (start fresh) |
| 55 | `feature/CL-55-icloud-on` | CL-54 (or `main`) | 5–6 | **before**: Xcode capabilities (spec → Manual steps 1); **during**: two-device pass |
| 56 | `feature/CL-56-icloud-line` | CL-55 (or `main`) | 7–8 | — |

Reviews: CL-53 — SOLID / clean code; CL-54 — SOLID; CL-55 — `swift-concurrency-pro` + SOLID; CL-56 —
`swift-concurrency-pro` + `swiftui-pro` + SOLID. Estimates (tests included): CL-53 ~450, CL-54 ~420, CL-55 ~380,
CL-56 ~330 (the natural end of the feature). If one is off, move the boundary and record it in `docs/plan.md`.

## Plan review (2026-11-26, folded in below)

- `swift-concurrency-pro`: (1) `NotificationCenter`'s `Notification` is not `Sendable`, so it never leaves the
  task that receives it: `StoreRemoteChanges.signals()` makes an `AsyncStream<Void>` with
  `makeStream(of:bufferingPolicy: .bufferingNewest(1))` (a burst of imports coalesces into one merge), forwards
  from a `Task` that iterates `NotificationCenter.default.notifications(named: .NSPersistentStoreRemoteChange)` and
  yields `()`, finishes the continuation when that loop ends, and cancels the task in `onTermination` (the `Task`
  handle is `Sendable`; no observer token is captured). No `@unchecked Sendable`. (2) `StoreSync.run()` is a
  main-actor `for await` driven by `RootView`'s `.task`, so SwiftUI's cancellation ends it; the merge is
  synchronous, so there is no reentrancy across an `await` — test `runEndsWhenItsTaskIsCancelled` (Task 5).
  (3) `accountStatus()` may outlive a cancelled `.task(id: scenePhase)`: `refreshCloudAccount()` checks
  `Task.isCancelled` after the `await` before it assigns, so an older answer cannot overwrite a newer one — test
  `aCancelledCheckLeavesTheLine` (Task 7). (4) `CKContainer(identifier:)` raises when the entitlement is missing,
  so `SystemCloudAccount` builds it inside `isAvailable()`, and only `live()` creates a `SystemCloudAccount`
  (CL-56, after the entitlements exist); tests and previews use the fake.
- `swiftui-pro`: the row is `Label(line.text, systemImage: line.systemImage)` (a `String` title, so no
  `Text(verbatim:)` wrapper and no `HStack`); the section stays a private struct taking the line, not the view model;
  the cloud check joins the existing `.task(id: scenePhase)` instead of a second `.task`. No other findings.

---

### Task 1: Revisions and the apartment merge rule

**Files:**
- Create: `CleanLog/Models/Sync/Revision.swift`, `CleanLog/Models/Sync/ApartmentDuplicates.swift`,
  `CleanLog/Models/Apartment/ApartmentName.swift`
- Modify: `CleanLog/Models/Apartment/ApartmentDraft.swift` (`isName(_:takenIn:excluding:)` compares
  `ApartmentName.matchKey`)
- Test: `CleanLogTests/Models/ApartmentDuplicatesTests.swift`, `CleanLogTests/Models/ApartmentNameTests.swift`

**Interfaces:**
- Produces:
  - `nonisolated struct Revision<Value: Sendable & Equatable>: Sendable, Equatable { var value: Value; var changedAt: Date }`.
  - `nonisolated enum ApartmentName { static func matchKey(_ name: String) -> String }` — trimmed of whitespace and
    newlines, then `folding(options: .caseInsensitive, locale: nil)`.
  - `nonisolated struct ApartmentMerge: Sendable, Equatable { let survivor: Revision<Apartment>; let removedIDs: Set<UUID> }`.
  - `nonisolated enum ApartmentDuplicates { static func merges(in apartments: [Revision<Apartment>]) -> [ApartmentMerge] }`
    — one merge per group of 2+ apartments with the same `matchKey`, sorted by the survivor's name key; none for a
    store without duplicates.

- [ ] **Step 1: Write the failing tests** (fixtures: `Apartment.fixture`, `changedAt` from `.warsaw(2026, 11, d)`;
  IDs built with `UUID(uuidString:)` so the order is known):
  - `namesMatchWithoutCaseAndSurroundingSpaces` — `matchKey(" 6Piw ") == matchKey("6piw")`,
    `matchKey("100") != matchKey("1 00")`.
  - `noMergeWithoutDuplicates` — "100", "101" → `[]`.
  - `theCopyChangedLastGivesItsValues` — "100" 28 zł changed on the 2nd and "100" 30 zł separate with code "1234#"
    changed on the 5th → survivor price 30 zł, `isReportedSeparately`, access code "1234#", `changedAt` the 5th.
  - `theSmallestIDSurvives` — survivor `id` is the smaller `uuidString` whichever copy is newer; `removedIDs` the other.
  - `keepsTheEarliestCreation` — survivor `createdAt` = the earlier `createdAt`.
  - `mergesThreeCopies` — three copies → one merge, two `removedIDs`.
  - `draftValidationUsesTheSameMatch` — `ApartmentDraft(name: " 6PIW ", …).validated(against: [6piw])` throws
    `.duplicateName`.
- [ ] **Step 2: Run** `-only-testing:CleanLogTests/ApartmentDuplicatesTests -only-testing:CleanLogTests/ApartmentNameTests`
  — fails to compile.
- [ ] **Step 3: Implement** the three files and the draft change.
- [ ] **Step 4: Run** the two suites and `ApartmentDraftTests` — pass.
- [ ] **Step 5: Commit** `Add the apartment duplicate merge rule`

### Task 2: The day merge rule

**Files:**
- Create: `CleanLog/Models/Sync/WorkDayDuplicates.swift`
- Modify: `CleanLog/Models/WorkDay/DayEntry.swift` (add `pointing(to:)`)
- Test: `CleanLogTests/Models/WorkDayDuplicatesTests.swift`

**Interfaces:**
- Consumes: `Revision` (Task 1).
- Produces:
  - `extension DayEntry { nonisolated func pointing(to apartmentID: UUID) -> DayEntry }` — the same entry with
    another `apartmentID`, snapshots untouched.
  - `nonisolated enum WorkDayDuplicates { static func merged(_ copies: [Revision<WorkDay>]) -> Revision<WorkDay> }` —
    `precondition(!copies.isEmpty)`; all copies have the same `day`. Also unites two entries of one apartment
    inside a single copy (after re-pointing, Task 4).

Rules (spec decisions 7, 9–11): copies ordered newest `changedAt` first (tie: smaller `id.uuidString` first);
`id` = smallest `id.uuidString`; `changedAt` = latest. Entries: walk the ordered copies' entries, first occurrence
per `apartmentID` gives the position and snapshot; `isCleaned` = any; `cleanedAt` = earliest non-nil among cleaned
ones. `manualDuration` = the newest copy's that is non-nil. `isTimerFinished`, `isTimeDropped` = the newest copy's.
Sessions — the folding the signature does not determine (an open session reaches `.distantFuture`, so it
swallows every later session and stays open):

```swift
let sorted = copies.flatMap(\.value.sessions).sorted { ($0.start, $0.id.uuidString) < ($1.start, $1.id.uuidString) }
var folded: [WorkSession] = []
for session in sorted {
    if let last = folded.last, session.start <= last.foldEnd {
        folded[folded.count - 1].end = last.foldEnd >= session.foldEnd ? last.end : session.end
    } else {
        folded.append(session)
    }
}
```

with a private `extension WorkSession { var foldEnd: Date { end ?? .distantFuture } }` in the same file.

- [ ] **Step 1: Write the failing tests** (`.warsaw(2026, 11, 13, h, m)` times):
  - `oneCopyIsItself` — merging `[copy]` returns it unchanged.
  - `unitesEntriesOfDifferentApartments` — newer copy [100], older [101] → [100, 101].
  - `aTickInEitherCopyIsKept` — newer copy 100 unticked, older 100 ticked at 10:00 → one 100, cleaned, `cleanedAt`
    10:00.
  - `theNewerSnapshotWins` — 100 at 28 zł (older) and 30 zł (newer) → 30 zł.
  - `unitesTwoEntriesOfOneApartmentInOneCopy` — one copy with two 100 entries → one.
  - `overlappingSessionsFold` — 9:00–11:00 and 10:00–12:00 → one 9:00–12:00 with the 9:00 session's `id`;
    `workedDuration` 3 h.
  - `separateSessionsStay` — 9:00–10:00 and 11:00–12:00 → both, sorted.
  - `anOpenSessionSwallowsLaterOnes` — 9:00–open and 10:00–11:00 → one 9:00–open (`timerState == .running`).
  - `theNewerManualDurationWins` — 2 h (older), 3 h (newer) → 3 h; nil (newer), 2 h (older) → 2 h.
  - `theNewerTimerFlagsWin` — newer finished, older paused → `isTimerFinished`.
  - `keepsTheSmallestIDAndTheLatestChange` — `id` and `changedAt` as the rules say.
- [ ] **Step 2: Run** `-only-testing:CleanLogTests/WorkDayDuplicatesTests` — fails to compile.
- [ ] **Step 3: Implement** `pointing(to:)` and `WorkDayDuplicates` (private helpers per rule: `mergedEntries`,
  `foldedSessions`).
- [ ] **Step 4: Run** the suite — pass; then build.
- [ ] **Step 5: Commit** `Add the day duplicate merge rule`

### Task 3: Stamp every write with its change time

**Files:**
- Modify: `CleanLog/Persistence/SchemaV1.swift` (`var changedAt = Date.distantPast` on `ApartmentRecord` and
  `WorkDayRecord`), `ApartmentRecord+Domain.swift`, `WorkDayRecord+Domain.swift`,
  `SwiftDataApartmentRepository.swift`, `SwiftDataWorkDayRepository.swift`, `App/AppDependencies.swift`
- Test: `CleanLogTests/Persistence/ApartmentRecordMappingTests.swift`, `WorkDayRecordMappingTests.swift`,
  `CleanLogTests/Persistence/ChangeStampTests.swift`

**Interfaces:**
- Consumes: `Revision` (Task 1).
- Produces: `ApartmentRecord.revision: Revision<Apartment>` and `apply(_ revision: Revision<Apartment>)`;
  `WorkDayRecord.revision: Revision<WorkDay>` and `apply(_ revision: Revision<WorkDay>)` (the existing
  `apply(_ value:)` stay and never touch `changedAt`). `SwiftDataWorkDayRepository(container:now:)` with
  `now: @escaping () -> Date = Date.init`. `StoreUnderTest.swiftData(now:)` passes `now` to both.

- [ ] **Step 1: Write the failing tests** — `ChangeStampTests` (in-memory container, `now` a mutable `TestClock`):
  `addStampsTheApartment`, `updateStampsTheApartment` (add at 9:00, update at 10:00 → `changedAt` 10:00),
  `aDayUpdateStampsTheDay`; read the records back with a `FetchDescriptor`. Mapping tests:
  `revisionCarriesChangedAt` for both records.
- [ ] **Step 2: Run** the three suites — fail.
- [ ] **Step 3: Implement**; set `changedAt = now()` in `add`, `update` and the day `update` after `apply`.
- [ ] **Step 4: Run** the persistence and repository contract suites — pass.
- [ ] **Step 5: Commit** `Stamp apartments and days with the time they changed`

### Task 4: Merge duplicates in the store

**Files:**
- Create: `CleanLog/Persistence/StoreDuplicateMerger.swift`
- Test: `CleanLogTests/Persistence/StoreDuplicateMergerTests.swift`

**Interfaces:**
- Consumes: `ApartmentDuplicates`, `WorkDayDuplicates`, `DayEntry.pointing(to:)`, the record `revision`/`apply`
  (Tasks 1–3).
- Produces: `final class StoreDuplicateMerger { init(container: ModelContainer); func mergeDuplicates() throws -> Bool }`
  — returns whether it saved.

Order inside one call: (1) apartments — for each `ApartmentMerge`, apply the survivor to its record, delete the
removed records, collect `removed → survivor` IDs; (2) re-point every `DayEntryRecord` whose `apartmentID` was
removed (one fetch with `#Predicate { removed.contains($0.apartmentID) }`); (3) days — group `WorkDayRecord`s by
`dayValue`; every group of 2+, and every day touched in (2), goes through `WorkDayDuplicates.merged`; the survivor
record gets `apply(revision)`, the others are deleted (their entries and sessions cascade); (4) `saveOrRollBack()`
only when `context.hasChanges`.

- [ ] **Step 1: Write the failing tests** (insert records straight into `container.mainContext` to fake an import):
  - `mergesTwoApartmentsWithTheSameName` — "100" and "100 " → one record, the newer price.
  - `repointsEntriesOfRemovedCopies` — a past day's entry pointing at the removed copy now points at the survivor.
  - `mergesTwoCopiesOfADay` — two `WorkDayRecord`s for the 13th with 100 and 101 → one record with both.
  - `unitesEntriesThatBecameTheSameApartment` — one day with entries for both copies of "100" → one entry.
  - `aCleanStoreIsNotSaved` — a store without duplicates → returns `false`; a second call after a merge → `false`.
- [ ] **Step 2: Run** `-only-testing:CleanLogTests/StoreDuplicateMergerTests` — fails to compile.
- [ ] **Step 3: Implement** with one private method per step above.
- [ ] **Step 4: Run** the suite, then the full tests — pass.
- [ ] **Step 5: Commit** `Merge duplicate apartments and days in the store`
- [ ] **Step 6:** note in `docs/plan.md`: delete CleanLog from the simulator and the phone once (schema changed in place).

### Task 5: Run the merge on every remote change

**Files:**
- Create: `CleanLog/Persistence/StoreSync.swift`, `CleanLog/Persistence/StoreRemoteChanges.swift`,
  `CleanLog/Persistence/ModelStorage.swift`
- Modify: `ModelContainerFactory.swift` (`make(_ storage: ModelStorage)`), both SwiftData repositories (add
  `func republish()` → `observers.notify()`), `App/AppDependencies.swift` (`let storeSync: StoreSync?`, nil in
  `preview`), `App/RootView.swift` (`.task { await dependencies.storeSync?.run() }`), test support
  (`ModelContainer.inMemory()` → `.make(.inMemory)`)
- Test: `CleanLogTests/Persistence/StoreSyncTests.swift`

**Interfaces:**
- Consumes: `StoreDuplicateMerger` (Task 4).
- Produces:
  - `nonisolated enum ModelStorage: Sendable, Equatable { case inMemory, onDevice, iCloud(containerID: String) }`
    → `ModelConfiguration` with `isStoredInMemoryOnly` and `cloudKitDatabase` `.none` / `.none` /
    `.private(containerID)`.
  - `nonisolated enum StoreRemoteChanges { static func signals() -> AsyncStream<Void> }` — one `Void` per
    `.NSPersistentStoreRemoteChange` (`import CoreData`), `bufferingNewest(1)`; see the plan review for its body.
  - `final class StoreSync { init(merger: StoreDuplicateMerger, apartments: SwiftDataApartmentRepository,
    workDays: SwiftDataWorkDayRepository, remoteChanges: @escaping () -> AsyncStream<Void> = StoreRemoteChanges.signals);
    func run() async }` — merges and republishes once, then once per signal; a thrown merge is logged
    (`Logger`) and the streams are republished anyway.
  - `AppDependencies.live()` still uses `.onDevice` in this task.

- [ ] **Step 1: Write the failing tests** (manual `AsyncStream<Void>.makeStream()`, `run()` in a `Task` cancelled
  at the end, `eventually`):
  - `mergesWhenItStarts` — two "100" records inserted before `run()` → the apartments stream yields one.
  - `mergesAndRepublishesOnARemoteChange` — after start, insert a second "100" and a day record, yield a signal →
    the apartments stream yields one "100" and the day stream yields the imported day.
  - `republishesWithoutDuplicates` — a signal with a new non-duplicate record → the stream yields it.
  - `runEndsWhenItsTaskIsCancelled` — cancel the task running `run()` → `await task.value` returns.
  - `storageChoosesTheCloudDatabase` — `ModelStorage.iCloud(containerID: "iCloud.com.cleanlog")` maps to a
    configuration whose `cloudKitContainerIdentifier == "iCloud.com.cleanlog"`; `.inMemory` has none.
- [ ] **Step 2: Run** `-only-testing:CleanLogTests/StoreSyncTests` — fails to compile.
- [ ] **Step 3: Implement**; `StoreSync` and the factory change; `live()` builds `StoreSync` from its container.
- [ ] **Step 4: Run** the full tests and build — pass.
- [ ] **Step 5: Commit** `Merge and refresh the store on every remote change`

### Task 6: Turn iCloud on

**Manual step before this task (the user):** spec → Manual steps 1. Stop and ask the user if it is not done
(`git status` shows no change to `CleanLog.xcodeproj/project.pbxproj` and no `.entitlements` file).

**Files:**
- Commit the user's Xcode changes: `CleanLog.xcodeproj/project.pbxproj` (Team, Bundle ID, `CODE_SIGN_ENTITLEMENTS`),
  the entitlements file (move it to `Config/CleanLog.entitlements` beside the Info.plist if Xcode put it elsewhere,
  and fix `CODE_SIGN_ENTITLEMENTS`), `Config/CleanLog-Info.plist` (`UIBackgroundModes` = `remote-notification`).
- Modify: `project.pbxproj` test target `PRODUCT_BUNDLE_IDENTIFIER = com.cleanlog.tests` and the same Team;
  `App/AppDependencies.swift` (`live()` uses `.iCloud(containerID: "iCloud.com.cleanlog")`, the ID a private
  static constant beside `live()`).

- [ ] **Step 1: Check** the entitlements contain `com.apple.developer.icloud-container-identifiers` =
  `[iCloud.com.cleanlog]`, `com.apple.developer.icloud-services` = `[CloudKit]` and `aps-environment`; the
  Info.plist has `UIBackgroundModes` with `remote-notification`; both configurations have the Team and Bundle ID.
- [ ] **Step 2: Implement** the `live()` change and the test bundle ID.
- [ ] **Step 3: Build, full tests** (the test host runs `live()`: the store must open on a simulator signed out of
  iCloud), lint.
- [ ] **Step 4: Two-device pass** (the user, with the session): delete the app from both; phone and simulator on the
  same Apple ID.
  1. Phone: add "100" and "101", plan and tick today → they appear on the simulator (open the app; allow a minute).
  2. Simulator: tick another apartment → Today on the phone updates without reopening the screen.
  3. Both offline (airplane mode / Mac Wi-Fi off): add "102" on both with different prices, plan today on both with
     a different tick each → back online: one "102" with the price set last, today has both ticks.
  4. Start the timer on both, stop on both → one day, the overlap counted once.
  Record in `docs/plan.md` what worked, what took long, and anything not checked. If screens do not refresh on an
  import, check whether `NSPersistentStoreRemoteChange` arrives (a `Logger` line in `StoreSync`); fall back to
  `NSPersistentCloudKitContainer.eventChangedNotification` with an ended `.import` event and record it.
- [ ] **Step 5: Commit** `Sync the store with iCloud`

### Task 7: The iCloud account in the settings view model

**Files:**
- Create: `CleanLog/Features/Settings/CloudAccount.swift` (protocol + `#if DEBUG` `FakeCloudAccount`),
  `CleanLog/App/SystemCloudAccount.swift`
- Modify: `Features/Settings/SettingsViewModel.swift`, `App/AppDependencies.swift` (`let cloudAccount: any CloudAccount`,
  preview default `FakeCloudAccount(isAvailable: true)`), `Features/Settings/SettingsView.swift` (pass it in
  `init(dependencies:)` only), `SettingsPreviewData.swift`, `Resources/Localizable.xcstrings` (the two row keys)
- Test: `CleanLogTests/Features/Settings/SettingsViewModelTests.swift`

**Interfaces:**
- Produces:
  - `protocol CloudAccount: AnyObject { func isAvailable() async -> Bool }`.
  - `final class SystemCloudAccount: CloudAccount` — `CKContainer(identifier: "iCloud.com.cleanlog")
    .accountStatus() == .available`; a thrown error logs and returns `false`.
  - `SettingsViewModel(settings:permission:cloudAccount:version:calendar:locale:)`;
    `private(set) var storageLine: SettingsStorageLine?` (nil until checked);
    `func refreshCloudAccount() async`.
  - `struct SettingsStorageLine: Equatable { let text: String; let systemImage: String }` in the view model's file —
    `icloud` + `settings.icloud.synced`, or `iphone` + `settings.icloud.local`.

- [ ] **Step 1: Write the failing tests**: `noStorageLineBeforeTheCheck`; `availableAccountReadsSynced`
  (`uk_UA` → «Синхронізовано з iCloud», glyph `icloud`); `unavailableAccountReadsLocal` (`en_US` →
  "Kept on this phone only", glyph `iphone`); `reCheckFollowsTheAccount` (fake flips to unavailable → second
  refresh shows local); `aCancelledCheckLeavesTheLine` (a gated fake: start a refresh, cancel its task, open
  the gate → `storageLine` stays nil).
- [ ] **Step 2: Run** `-only-testing:CleanLogTests/SettingsViewModelTests` — fails to compile.
- [ ] **Step 3: Implement** (catalog keys in both languages).
- [ ] **Step 4: Run** the suite and the full tests — pass.
- [ ] **Step 5: Commit** `Read the iCloud account for Settings`

### Task 8: The iCloud line in Settings

**Files:**
- Modify: `Features/Settings/SettingsView.swift`, `SettingsPreviewData.swift`, `Resources/Localizable.xcstrings`
  (`settings.icloud.header`)

**Interfaces:**
- Consumes: `SettingsViewModel.storageLine`, `refreshCloudAccount()` (Task 7).

- [ ] **Step 1: `SettingsStorageSection`** (a private struct in `SettingsView.swift`) — a `Section` with header
  «iCloud», one row `Label(line.text, systemImage: line.systemImage)`, `Card` row
  background, `Ink` text, `InkSecondary` header; shown `if let line = viewModel.storageLine`, after the reminder and
  permission sections, before the version footer.
- [ ] **Step 2:** the existing `.task(id: scenePhase)` also awaits `viewModel.refreshCloudAccount()` when `.active`.
- [ ] **Step 3: Previews** — synced (light), local (dark).
- [ ] **Step 4: Run it** on the iPhone 16 simulator signed out and signed in to iCloud, uk and en, `accessibility5`.
- [ ] **Step 5: Build, full tests, lint; commit** `Show in Settings whether the data syncs with iCloud`
