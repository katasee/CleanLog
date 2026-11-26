# iCloud sync — design

Feature 10 of the roadmap. Product spec: `docs/superpowers/specs/2026-11-13-cleanlog-design.md` (iCloud sync,
decided 2026-11-24 in CL-26). Builds on the CloudKit-compatible `SchemaV1` records, `ModelContainerFactory`,
the SwiftData repositories and their `StoreObservers` streams, and the Settings sheet (Feature 9). There is no
artboard for the iCloud line; it follows the Settings sheet's existing `Card` rows.

## Intent

When she changes or resets her phone, she installs CleanLog, signs in with the same Apple ID and carries on with
her apartments and every past month. SwiftData keeps the store in her private CloudKit database; nothing of ours
runs on a server and there is no sign-in screen.

## Goals

- The store syncs with the private CloudKit database of container `iCloud.com.cleanlog`.
- A change that arrives from iCloud refreshes every screen showing that data, exactly like a local save does.
- Two devices that created the same apartment or the same day while offline end up with one apartment and one day,
  and no cleaned apartment and no worked minute is lost.
- Settings always shows one iCloud line: «Синхронізовано з iCloud» / "Synced with iCloud" when the iCloud account
  is available, «Зберігається лише на цьому телефоні» / "Kept on this phone only" otherwise.
- Without an iCloud account, or with iCloud off for the app, the app works locally exactly as before.

## Non-goals

- Migrating data from builds before this feature: **start fresh** (nobody uses a build for real yet). `SchemaV1`
  changes in place one last time; delete the app from the phone and the simulator after CL-54.
- Syncing the reminder settings (product spec → Settings: they stay on the phone).
- A sync progress indicator, a "sync now" button, conflict screens, or sharing data with another person.
- Showing *why* iCloud is unavailable (no account, restricted, off for the app): the line only says the data stays
  on this phone.

## Anti-goals

- A tick or a worked minute that disappears because another device had an older or emptier copy of the day.
- Two devices merging the same duplicates differently and then deleting each other's survivor.
- A merge that bumps the "changed last" time and so makes an old copy look new.
- A screen that needs leaving and reopening to show what just arrived from iCloud.

## Decisions taken in the brainstorm (2026-11-26)

1. **Bundle ID `com.cleanlog`**, an explicit App ID with iCloud (CloudKit) on the developer portal, Team ID
   `78HWZYA4DR` (Individual, paid program). The CloudKit container is **`iCloud.com.cleanlog`**; it is created in the
   manual step before CL-55. The test target becomes `com.cleanlog.tests`. This settles the Bundle ID for
   Feature 11.
2. **Offline duplicates merge, the newer change wins.** Apartments whose names match without case and surrounding
   spaces are one apartment; the one changed last keeps its price and report flag. Two copies of one day become one:
   entries are united and the timer sessions combined.
3. **The iCloud line in Settings is always shown** (two texts above).
4. **No migration: start fresh.**
5. **Checked by hand on a phone and a simulator** signed in to the same Apple ID.

Claude's calls (the user may correct them):

6. **"Changed last" is a `changedAt: Date` on `ApartmentRecord` and `WorkDayRecord`**, set from the repository's
   clock on every write (`add`, `update`, every day `update`). It is persistence metadata: the domain types do not
   carry it; the merge works on `Revision<Value>` (a value plus its `changedAt`). A merged result takes the latest
   `changedAt` of its copies, never "now". Device clocks are trusted as they are.
7. **The survivor of a merge keeps the smallest `id`** (by `uuidString`) of the copies, so two devices merging
   the same copies independently keep the same record and delete the same others.
8. **Apartments:** the merged apartment takes the name spelling, price, access code and report flag of the copy
   changed last; `createdAt` is the earliest. Every entry that pointed at a removed copy is re-pointed to the
   survivor (history keeps its snapshots: name, price and flag of an entry never change).
9. **Days, entries:** entries are united by `apartmentID`. For the same apartment the snapshot (name, price, flag)
   comes from the copy changed last, but **a tick is never lost**: the entry is cleaned if either copy has it
   cleaned, with the earlier `cleanedAt`. Order: the newer copy's entries in its order, then the rest in theirs.
10. **Days, sessions:** all sessions of both copies, sorted by start; sessions that overlap or touch fold into one
    (earliest start, latest end; an open session extends to "now" and folds everything after its start into
    itself, so the result has at most one open session). A folded session keeps the earliest session's `id`.
    The same minute is never counted twice.
11. **Days, the rest:** two manual durations → the one from the copy changed last; one → that one. The timer flags
    (`isTimerFinished`, `isTimeDropped`) come from the copy changed last.
12. **When it runs:** once when the app starts and after every remote change. The merge saves only when it found
    a duplicate, so its own save does not start an endless loop.
13. **The iCloud line** is a section headed «iCloud» with one row: an `icloud` glyph and the synced text, or an
    `iphone` glyph and the local text. It appears after the first account check (a fraction of a second), so it never
    flashes the wrong text, and is re-checked every time the app becomes active (the same moment the notification
    permission is re-read). No footer.
14. **The account check** is `CKContainer(identifier: "iCloud.com.cleanlog").accountStatus()`: `.available` is
    "synced"; every other status, and an error, is "on this phone only".

## How sync works

- `ModelContainerFactory.make(_ storage:)` takes `.inMemory` (tests, previews), `.onDevice` or
  `.iCloud(containerID:)`; the app uses `.iCloud("iCloud.com.cleanlog")` from CL-55 on. SwiftData's CloudKit
  mirroring needs the iCloud + CloudKit and Push Notifications entitlements and the remote-notifications background
  mode; without an iCloud account it simply keeps the store local and starts syncing once she signs in.
- A remote change is the store's `NSPersistentStoreRemoteChange` notification. `StoreSync` (`Persistence/`)
  listens from `RootView`'s `.task`: on start and on every change it merges duplicates in the main context and then
  tells both SwiftData repositories to re-yield their streams.
- Uniqueness stays the repositories' job (records keep no unique constraints): local writes never create a
  duplicate (`add` validates the name, a day `update` writes the stored record); only an import can.

## Manual steps (the user, by hand)

1. **Before CL-55** (Xcode, project `CleanLog`, target `CleanLog` → Signing & Capabilities):
   - Team: `78HWZYA4DR`; Bundle Identifier: `com.cleanlog`; Automatically manage signing on.
   - "+ Capability" → **iCloud**: tick **CloudKit**, then "+" under Containers → `iCloud.com.cleanlog` (this creates
     the container on the developer portal) and tick it.
   - "+ Capability" → **Background Modes**: tick **Remote notifications**.
   - Check that **Push Notifications** appeared with iCloud (add it with "+ Capability" if not).
   - Leave the changes uncommitted; the CL-55 session checks and commits them.
2. **During CL-55** — the two-device pass: an iPhone and a simulator (Settings → Apple Account) signed in to the
   same Apple ID, the app deleted from both first. The session lists what to try (Task 6).
3. **Before the first TestFlight build (Feature 11)** — CloudKit Console → container `iCloud.com.cleanlog` →
   "Deploy Schema Changes…" from Development to Production.
