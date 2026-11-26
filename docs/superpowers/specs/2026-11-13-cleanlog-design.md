# CleanLog — product spec

Started 2026-11-13. The product-wide spec: keep it current with every scope decision.
Visual reference: https://claude.ai/artifact/SjjoWCGv15bAQJmGVeRCbM (Claude Design canvas).

## Why

The developer's mother cleans apartments. She cleans mostly the same small set of apartments; she
learns the next day's list in the evening. Once a month she writes down by hand which apartments she
cleaned on which day and sends that report to her boss over WhatsApp. Today that is notes plus
manual counting, with mistakes (missing commas and brackets, wrong counts).

CleanLog is a work log for cleaners: plan the day → tick apartments off → earnings add up by
themselves → the monthly report goes to WhatsApp in one tap, in the exact format the boss already
knows. Plus statistics on earnings and time worked.

First for her (TestFlight), then on the App Store as a general tool for cleaners. The developer has
an Apple Developer account.

## Goals

- Daily use is faster than notes: marking an apartment done is one tap.
- The report is generated in exactly the format below, with no mistakes.
- Today's and this month's earnings are always visible.
- Time worked → hours and earnings per hour.
- A new phone loses nothing: install the app with the same Apple ID and the template and history
  are there.
- Enough substance to pass App Store review (Guideline 4.2, minimum functionality).

## Non-goals (v1)

- Accounts, a server, sharing between users, a boss-side view.
- Addresses or buildings (an apartment name is free text; that is enough).
- Cleaning types (regular / deep).
- A timer per apartment.
- Android, iPad, landscape.
- Charts in Statistics (removed after the design review: the numbers are what matters).

## Anti-goals

- A daily flow slower or more complicated than writing it in notes.
- A report that differs from what the boss is used to.
- Losing data: deleting an apartment or changing a price rewrites past months, or a new phone
  starts empty.
- Anything hard-coded to one person or company.

## Constraints

- iOS 18.0+, iPhone only, portrait. SwiftUI, SwiftData, Swift Testing, Swift 6.
- Liquid Glass on iOS 26 (system bars and sheets, plus our own controls), material fallback on 18.
- Data on the device and in the user's own private iCloud database; no server of ours. No data collection (the App Store still needs a privacy policy page).
- Languages: Ukrainian and English (no Polish). Złoty (zł) only for now; no currency setting.

## Approaches considered

| | Approach | Pros | Cons |
|---|---|---|---|
| **A (chosen)** | SwiftUI + SwiftData | least code, CloudKit later without a rewrite | needs iOS 17+ (we target 18) |
| B | SwiftUI + Core Data, iOS 15+ | older iPhones | more and older code |
| C | Flutter / React Native | Android | the target is the App Store; native is easier to make good and to get through review |

## Screens

A system `TabView` with three tabs — **Today**, **Statistics**, **Apartments**. There is no floating
add button (dropped 2026-11-24): a day's apartments are added from the Today screen. Settings open from a toolbar button on Apartments.

### Today

Shows the selected day; it is today on launch.

- **Header**: the date with ‹ › to step one day, and a calendar button.
- **Timer card**: idle shows `0:00:00` and **Start**; running shows the elapsed time, the start time,
  **Pause/Resume** and **Stop**.
- **Two summary cards**: today `earned / planned zł` with a progress bar; this month's total and
  count.
- **Apartment list**: one row per planned apartment — check circle, name, an "окремо" badge if it is
  reported separately, and the apartment's access code with a key glyph (`🔑 4821`) instead of the
  price: on site the code is what matters; the money is in the summary cards. Tapping a row toggles cleaned. Swipe to remove it from the day.
- **Empty state** (nothing planned yet): "Які квартири сьогодні?" with **Додати квартири** (opens
  Day plan) and **Як учора · N квартир**, which copies the most recent working day's plan, unticked.
- Unticked apartments are not carried over; they are simply not counted and not reported.

### A future day

The same screen for any later date, reached by › or the calendar — for planning ahead.

- Apartments can be added and removed; ticking and the timer are disabled, since nothing can be
  cleaned in advance. The empty state offers the same two buttons as today.
- Future entries are never counted in Statistics or the report until they are ticked on their day.

### A past day

The same screen for any earlier date, reached by ‹ or the calendar.

- The title is the date ("12 листопада"), the subtitle the weekday and "минулий день", and a
  **Сьогодні** button jumps back.
- The timer card shows the day's total ("5:10", "07:30 – 13:05 · пауза 25 хв") with **Змінити** to
  set the duration by hand (for a forgotten timer).
- Rows can be ticked and unticked; the list's **+ Додати квартиру** row adds one that was forgotten.
- Changes flow into Statistics and the report at once.

### Calendar (sheet)

Opened from a calendar button in the day header, on every day. Design:
`docs/superpowers/specs/2026-11-24-calendar-design.md`.

- Quick buttons: **Сьогодні**, **Учора**, **Тиждень тому** — they select the day; they do not open it.
- A month grid, weeks starting on the locale's first weekday (Monday for uk). A day that earned
  something shows the amount in small type; planned or empty days show the number alone. Today is
  ringed; the selected day is filled. Month paging ‹ ›.
- A card for the selected day: weekday, date, and «4 квартири · 140 zł» when something was cleaned,
  «5 квартир» when it is only planned, «вихідний» otherwise; **Відкрити день** closes the sheet and
  shows that day.
- Future days are selectable (the canvas still shows them disabled; the spec wins): the list for
  tomorrow usually arrives the evening before.

### Day plan (sheet)

Opened from the empty day's **Додати квартири** and from a **+ Додати квартиру** row at the end of the
day's list (on every day). Design: `docs/superpowers/specs/2026-11-24-day-plan-design.md`.

- A grid of the template apartments **not yet on the day** (name + price), multi-select. The sheet only
  adds; removing stays the swipe on the day. A search field filters by name.
- **Нова** creates an apartment (name, price, "окремо у звіті"), saves it to the template and returns to
  the grid with it selected.
- The confirm button sums the selection: "Додати 7 квартир · 224 zł". Nothing changes until it is
  tapped.

### Statistics

- Month switcher; it opens on the current month and goes no further forward.
- The month's earnings as one large number, with the change against the previous month («↑ 9% до
  жовтня») on a finished month only — hidden on the current month, and when either month earned zero.
- Cards: apartments cleaned (all, including separately reported ones), hours worked, earnings per
  hour (only over days with recorded time; "—" when none), average per working day (a day with at
  least one cleaned apartment).
- A day's time counts once its work is over: a manual duration, a past day, or today with the timer
  finished. Today's running or paused timer adds nothing until it is finished.
- Most frequent apartments (the top three) with their counts.
- A **Звіт** button opens the report for the shown month; it is disabled on a month with nothing cleaned.
- Details: `2026-11-25-statistics-design.md`.

### Report (sheet)

- The title «Звіт за листопад» (with the year for a month of another year), the month's working days and
  cleaned apartments («12 днів · 63 квартири»), and a monospaced, scrollable preview of the report text.
- **Надіслати у WhatsApp** → `whatsapp://send?text=<percent-encoded>`, every reserved character encoded so
  `+155` arrives as `+155` (`whatsapp` in `LSApplicationQueriesSchemes`). When WhatsApp is not installed, the
  button is **Поділитися** and opens the system share sheet.
- **Копіювати** → the pasteboard, confirmed by a checkmark for two seconds.
- Details: `2026-11-25-report-design.md`.

### Apartments (template)

- The list: name, price, an "окремо у звіті" badge. Add, edit, delete (a confirmed swipe); sorted by
  name — digit-only names numerically first, then the rest.
- An apartment has an optional, permanent **access code** (free text, e.g. `4821` or `1234#`),
  edited in the template and shown on the Today rows.
- Names are unique (case- and edge-whitespace-insensitive).
- A price change applies to new entries only.

### Settings

A sheet opened from a settings button in the Apartments toolbar. Details:
`2026-11-26-settings-design.md`.

- A reminder to send the report on the last day of the month, **off by default**; when switched on, a time
  picker appears, starting at 18:00. Notification permission is asked only when it is switched on.
- No reminder for a month with nothing cleaned. Tapping the notification opens that month's report.
- When notifications are denied for the app, a row says so and opens the system settings.
- The app's version and build.
- The reminder settings stay on the phone (not synced).
- An iCloud line, always shown: «Синхронізовано з iCloud» ("Synced with iCloud") when the iCloud account is
  available, «Зберігається лише на цьому телефоні» ("Kept on this phone only") otherwise (Feature 10).
- No morning reminder in v1 (dropped 2026-11-26). The privacy policy link comes with the App Store preparation
  (Feature 11).

## Report format

The real October report this must reproduce:

```
1.10-(54,96,100,105,115,116,138)=7
2.10-(54,64,96,105,115,138,6piw)=7+155
3.10-(54,64,96,100,105,115,116)=7+155
4.10-(54,64,96,100,105,115,116,138)=8+155

5.10-(54,96,100,105,115,138,6piw)=7
...
```

- Only days with at least one cleaned apartment; only cleaned entries.
- A line is `{d}.{M}-({names, comma-separated, no spaces})={count}`, then `+{name}` for each
  apartment marked "окремо у звіті" — one with a different rate, like `155` in the example or
  `106` (56 zł against 28 zł for the rest) in the test data.
  - The date has no leading zeros: `1.10`, `13.11`.
  - Inside the brackets: entries in apartment name order: digit-only names numerically, then the rest.
  - `{count}` counts the entries inside the brackets only.
  - A day with only separate apartments: `{d}.{M}-` and their names joined by `+`, no brackets and no
    count: `5.11-155`, `5.11-106+155` (confirmed with the user, 2026-11-25).
- Weeks are separated by one blank line and always start on Monday, whatever the device locale:
  it is the boss's fixed format (the October example breaks after Sunday the 4th). The calendar
  grid is the one that follows the locale.
- No header and no total line, exactly like the example.
- Names and the separate flag come from the entry's snapshot.

## Data model

Domain value types (`Models/`), mirrored by SwiftData records (`Persistence/`) that are
CloudKit-compatible: every attribute optional or defaulted, relationships optional, no unique
constraints (uniqueness is enforced in code). `ApartmentRecord` and `WorkDayRecord` also store `changedAt`, the
time of their last write, which only the iCloud duplicate merge reads.

- **Apartment**: `id`, `name`, `price: Money`, `accessCode?`, `isReportedSeparately`, `createdAt`.
- **WorkDay**: `id`, `day: DayKey`, `entries`, `sessions`, `manualDuration: Duration?`.
- **DayEntry**: `id`, `apartmentID?`, snapshots `name`, `price`, `isReportedSeparately`;
  `isCleaned`, `cleanedAt?`.
- **WorkSession**: `id`, `start: Date`, `end: Date?`.
- **Money**: integer minor units (28 zł = 2800); złoty only.
- **DayKey**: year, month, day — a calendar day independent of time zone.

Timer rules: a day's duration is the sum of its sessions, or `manualDuration` when set; pausing ends a
session and resuming starts a new one; a session crossing midnight belongs to the day it started; the
state is timestamps, so it survives the app being killed. A Live Activity with the running time is
planned for after v1's core screens.

## iCloud sync

Decided 2026-11-24, in v1, so the first TestFlight data already lives in iCloud. The point: when the
user changes or resets her phone, she installs CleanLog, signs in with the same Apple ID and carries
on. An iPhone backup does not cover that (it restores only a whole phone, and a deleted app takes its
data with it); a manual export would be forgotten.

Details: `2026-11-26-icloud-sync-design.md`.

- SwiftData syncs the store with the user's **private** CloudKit database (`cloudKitDatabase:
  .private("iCloud.com.cleanlog")`): no server, no account, no sign-in screen. Bundle ID `com.cleanlog`,
  Team `78HWZYA4DR`. Capabilities: iCloud + CloudKit, background
  remote notifications.
- Changes that arrive from iCloud refresh the screens like local saves: the repository streams yield
  again on a remote change.
- Duplicates are merged in the store: two devices that created the same `DayKey` or an apartment with the same
  name (without case and surrounding spaces) while offline end up as one day / one apartment. The newer change
  wins: the apartment changed last keeps its price and report flag; a day's entries are united (a tick in either
  copy is kept) and its timer sessions combined (overlaps counted once).
- No iCloud account or iCloud off for the app: the app works locally as before and Settings says so in a
  line that the data is kept on this phone only (added to Settings by this feature).
- Not synced: the reminder settings — on a new phone they are switched on again (the notification
  permission has to be granted again anyway).
- No migration of data from earlier builds: the store starts fresh (nobody used a build for real).
- Checked by hand on a phone and a simulator signed in to the same Apple ID.
- The CloudKit schema is deployed to production before the first TestFlight build.

## Testing

- Unit tests for the report builder (the October example, including `6piw`, `133kol`, `+155` and the
  week breaks), the money and duration arithmetic (pauses, midnight, manual duration, per-hour rate),
  and the month totals.
- View models against fake repositories; SwiftData repositories against an in-memory container.
- A manual pass on a device through TestFlight.

## Left to the builder

- Project and target structure (the Bundle ID is `com.cleanlog`, decided 2026-11-26), the widget extension for the Live Activity.
- Onboarding: the first launch should lead to "add your apartments".

## Later (not v1)

- App Store submission: screenshots, description, privacy policy page (its link goes into Settings then).
- Home-screen widget, Live Activity.
- PDF/CSV export.
