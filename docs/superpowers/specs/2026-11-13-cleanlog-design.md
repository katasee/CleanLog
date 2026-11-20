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
- Enough substance to pass App Store review (Guideline 4.2, minimum functionality).

## Non-goals (v1)

- Accounts, a server, sharing between users, a boss-side view.
- Addresses or buildings (an apartment name is free text; that is enough).
- Cleaning types (regular / deep).
- A timer per apartment.
- Android, iPad, landscape.
- iCloud sync — but the store must be CloudKit-compatible so it can be switched on later.
- Charts in Statistics (removed after the design review: the numbers are what matters).

## Anti-goals

- A daily flow slower or more complicated than writing it in notes.
- A report that differs from what the boss is used to.
- Losing data: archiving an apartment erases history, or a price change rewrites past months.
- Anything hard-coded to one person or company.

## Constraints

- iOS 18.0+, iPhone only, portrait. SwiftUI, SwiftData, Swift Testing, Swift 6.
- Liquid Glass on iOS 26 (system bars and sheets, plus our own controls), material fallback on 18.
- All data on the device. No data collection (the App Store still needs a privacy policy page).
- Languages: Ukrainian, Polish, English. Złoty (zł) only for now; no currency setting.

## Approaches considered

| | Approach | Pros | Cons |
|---|---|---|---|
| **A (chosen)** | SwiftUI + SwiftData | least code, CloudKit later without a rewrite | needs iOS 17+ (we target 18) |
| B | SwiftUI + Core Data, iOS 15+ | older iPhones | more and older code |
| C | Flutter / React Native | Android | the target is the App Store; native is easier to make good and to get through review |

## Screens

A system `TabView` with three tabs — **Today**, **Statistics**, **Apartments** — and a floating
add button beside the tab bar. Settings open from a toolbar button on Apartments.

### Today

Shows the selected day; it is today on launch.

- **Header**: the date with ‹ › to step one day, and a calendar button.
- **Timer card**: idle shows `0:00:00` and **Start**; running shows the elapsed time, the start time,
  **Pause/Resume** and **Stop**.
- **Two summary cards**: today `earned / planned zł` with a progress bar; this month's total and
  count.
- **Apartment list**: one row per planned apartment — check circle, name, an "окремо" badge if it is
  reported separately, price. Tapping a row toggles cleaned. Swipe to remove it from the day.
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
- Rows can be ticked and unticked; **+ Додати квартиру** adds one that was forgotten.
- Changes flow into Statistics and the report at once.

### Calendar (sheet)

- Quick buttons: **Сьогодні**, **Учора**, **Тиждень тому**.
- A month grid, weeks starting on the locale's first weekday (Monday for pl/uk). Each worked day
  shows its earnings in small type; today is ringed; the selected day is filled. Month paging ‹ ›.
- A card for the selected day (weekday, date, count, earnings) with **Відкрити день**.
- Future days are selectable (the canvas still shows them disabled; the spec wins): the list for
  tomorrow usually arrives the evening before.

### Day plan (sheet)

- A grid of template apartments (name + price), multi-select; apartments already on the day are
  shown selected. A search field filters by name.
- **Нова** creates an apartment (name, price, "окремо у звіті"), saves it to the template and adds it
  to the day.
- The confirm button sums the selection: "Додати 7 квартир · 224 zł".

### Statistics

- Month switcher.
- The month's earnings as one large number, with the change against the previous month (hidden
  when the previous month is zero).
- Cards: apartments cleaned (all, including separately reported ones), hours worked, earnings per
  hour (only over days with recorded time; "—" when none), average per working day (a day with at
  least one cleaned apartment).
- Most frequent apartments with their counts.
- A **Звіт** button opens the report for the shown month.

### Report (sheet)

- A monospaced preview of the report text.
- **Надіслати у WhatsApp** → `whatsapp://send?text=<percent-encoded>` (`whatsapp` in
  `LSApplicationQueriesSchemes`); without WhatsApp, the system share sheet.
- **Копіювати** → the pasteboard.

### Apartments (template)

- The list: name, price, an "окремо у звіті" badge. Add, edit, reorder, archive.
- Names are unique among active apartments (case- and edge-whitespace-insensitive).
- A price change applies to new entries only; the footnote says so.

### Settings

- Reminder on the last day of the month at 18:00 to send the report (permission asked only when
  switched on).
- Optional morning reminder to plan the day, with a time (off by default).
- Privacy policy link, version.

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
  - Inside the brackets: entries in template order.
  - `{count}` counts the entries inside the brackets only.
  - A day with only separate apartments: `{d}.{M}-()=0+155`. *(assumed; confirm with the boss's
    expectations)*
- Weeks are separated by one blank line; the first weekday follows the locale (Monday for pl/uk —
  the October example breaks after Sunday the 4th, which matches).
- No header and no total line, exactly like the example.
- Names and the separate flag come from the entry's snapshot.

## Data model

Domain value types (`Models/`), mirrored by SwiftData records (`Persistence/`) that are
CloudKit-compatible: every attribute optional or defaulted, relationships optional, no unique
constraints (uniqueness is enforced in code).

- **Apartment**: `id`, `name`, `price: Money`, `isReportedSeparately`, `sortOrder`, `isArchived`,
  `createdAt`.
- **WorkDay**: `id`, `day: DayKey`, `entries`, `sessions`, `manualDuration: Duration?`.
- **DayEntry**: `id`, `apartmentID?`, snapshots `name`, `price`, `isReportedSeparately`,
  `sortOrder`; `isCleaned`, `cleanedAt?`.
- **WorkSession**: `id`, `start: Date`, `end: Date?`.
- **Money**: integer grosze (28 zł = 2800); złoty only.
- **DayKey**: year, month, day — a calendar day independent of time zone.

Timer rules: a day's duration is the sum of its sessions, or `manualDuration` when set; pausing ends a
session and resuming starts a new one; a session crossing midnight belongs to the day it started; the
state is timestamps, so it survives the app being killed. A Live Activity with the running time is
planned for after v1's core screens.

## Testing

- Unit tests for the report builder (the October example, including `6piw`, `133kol`, `+155` and the
  week breaks), the money and duration arithmetic (pauses, midnight, manual duration, per-hour rate),
  and the month totals.
- View models against fake repositories; SwiftData repositories against an in-memory container.
- A manual pass on a device through TestFlight.

## Left to the builder

- Bundle ID (decided later), project and target structure, the widget extension for the Live Activity.
- Onboarding: the first launch should lead to "add your apartments".

## Later (not v1)

- iCloud sync.
- App Store submission: screenshots, description, privacy policy page.
- Home-screen widget, Live Activity.
- PDF/CSV export.
