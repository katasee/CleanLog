# Calendar — design

Feature 6 of the roadmap. Product spec: `docs/superpowers/specs/2026-11-13-cleanlog-design.md`
(Calendar). Visual reference: the `Calendar` artboard on the design canvas (the header button is on the
`Main` and `PastDay` artboards). Builds on Today (`2026-11-22-today-design.md`), which left the calendar
button out until the sheet exists.

## Intent

The day screen steps one day at a time; the calendar is how the cleaner reaches any other day in a few
taps: a past day she forgot to log or wants to correct, or tomorrow, whose list usually arrives the
evening before. On the way it shows the month at a glance — which days earned what.

## Goals

- A calendar button in the day header, on every kind of day, that opens the calendar as a sheet.
- Quick buttons «Сьогодні», «Учора», «Тиждень тому».
- A month grid: weeks start on the locale's first weekday; a day that earned something shows the amount
  under its number; today is ringed; the selected day is filled; ‹ › page months.
- A card for the selected day with **«Відкрити день»**, which closes the sheet and shows that day on
  the Today tab.
- Every day is selectable: past, today and future.

## Non-goals

- Planning or ticking from the calendar; the day screen does that.
- A month total in the calendar (Statistics shows it).
- Marking planned-but-not-cleaned days in the grid (the user's decision, 2026-11-24: option B).
- Paging limits: any month back or forward can be shown.

## Anti-goals

- A sum under a number that cannot be read: the amount must stay legible as text grows, or move out of
  the cell (it stays in the VoiceOver label).
- A sum that differs from the day screen's for the same day: both use `WorkDay.earned`.
- A grid that shifts the week start by the device's time zone or by a `Date` at midnight: the grid is
  built from `DayKey`s and an explicit `Calendar`.

## Decisions taken in the brainstorm (2026-11-24)

1. **The grid shows only earnings** (the user's choice, option B). A day with cleaned entries shows its
   `earned` under the number; a planned future day, a planned day with nothing cleaned, and an empty
   day all show the number alone.
2. **The selected-day card** (Claude's proposal, accepted):
   - the day has cleaned entries → «4 квартири · 140 zł» (cleaned count and earned);
   - else it has planned entries → «5 квартир» (the planned count, no sum);
   - else → «вихідний».
   Above it the weekday («Пʼятниця»; today reads «Сьогодні · Пʼятниця») and the date («13 листопада»).
3. **Quick buttons only select** (accepted): they select their day and page the grid to its month; the
   matching button shows as pressed. They never open the day — «Учора» in one tap is already the header's ‹.
4. **«Відкрити день»** dismisses the sheet and sets the Today tab's day to the selected one. Coming back
   is the header's «Сьогодні», as today.
5. **The sheet opens on the day being shown**: that day is selected, its month on the grid.
6. **The calendar button sits in the header's trailing corner on every day**; on a past or future day it
   is beside «Сьогодні», as on the `PastDay` artboard.
7. **Future days are selectable** (the product spec already overrides the canvas, which shows them
   disabled).

## Approaches

| # | Approach | Trade-off | Verdict |
|---|---|---|---|
| 1 | Our own SwiftUI grid: 7 columns, a custom cell (number, sum, ring, fill); the month layout is a pure function in `Models/` | matches the artboard, full control of Dynamic Type; we write the cell's accessibility and the paging | **chosen** |
| 2 | `UICalendarView` wrapped for SwiftUI, sums as decorations | system paging and accessibility; a decoration is too small for «224» at large text, the selection and ring are the system's, first UIKit in the app | rejected |
| 3 | `DatePicker(.graphical)` | — | ruled out: no content under a day number |

## The sheet

```
 ✕            ‹  Листопад 2026  ›
 [ Сьогодні ] [  Учора  ] [Тиждень тому]
 ┌──────────────────────────────────────┐
 │ Пн  Вт  Ср  Чт  Пт  Сб  Нд           │
 │                          1    2      │
 │                         224  168     │
 │  3   4   5   6   7   8   9           │
 │ 112 224 140 ▓6▓ 196       196        │   ▓ selected   ◯ today
 │ 10  11  12 (13) 14  15  16           │
 │ 112 224 140 140                      │
 │ …                                    │
 └──────────────────────────────────────┘
 ┌──────────────────────────────────────┐
 │ Пʼятниця                  5 квартир  │
 │ 6 листопада                 140 zł   │
 │ [          Відкрити день           ] │
 └──────────────────────────────────────┘
```

- **Header**: ✕ dismisses; the month title («Листопад 2026 р.» — Foundation's Ukrainian month-and-year form, kept rather than cut with a fixed pattern; a `Formatting/` template formatter) between
  ‹ and ›, each a 44 pt target with an accessibility label.
- **Weekday row**: short standalone weekday symbols from the calendar and locale, rotated to start at
  `calendar.firstWeekday` (through `Formatting/`), hidden from VoiceOver (each cell reads its own date).
- **Cells**: blank cells before the 1st; each day a button with the number and, if it earned something,
  the amount as a number without «zł» (a new `MoneyFormat` variant — the column is too narrow for the
  currency; the VoiceOver label says it in full: «6 листопада, 140 zł»). Today: an `AccentColor` ring
  and accent text; selected: an `AccentColor` fill; selected also gets the selected trait. Digits
  `.monospacedDigit()`.
- **Card**: on `.cardSurface()`, the lines of decision 2, and the prominent «Відкрити день» button.
- The grid's earnings follow the store: a tick on another device (later, with sync) or a change while the
  sheet is open updates the cell.

## Behaviour

- `CalendarViewModel` observes `workDays.days(in: shownMonth)` for the grid and `workDays.day(selected)`
  for the card. The card has its own stream because the selected day may be in another month than the
  one on the grid (paging does not move the selection — Claude's call).
- Paging changes `shownMonth`; the view restarts the month observation with `.task(id:)` on it, and the
  card's with `.task(id:)` on the selection (Claude's call: `observe()` per stream, so SwiftUI cancels the
  old one).
- `today` is fixed when the sheet opens; a midnight passing while it is open is not followed (Claude's
  call: the sheet is short-lived, and the Today tab advances on its own).
- **Open day** calls back to `TodayView`, which owns `TodaySelection`; it gains `show(_ day:)`. The sheet
  is presented by `TodayView`, not `DayView`: `DayView` is rebuilt (`.id(selection)`) when the day changes,
  which would tear the sheet down mid-dismiss.

## Code shape

- `Models/MonthGrid.swift`: `MonthGrid.weeks(of month: MonthKey, calendar: Calendar) -> [[DayKey?]]`
  (leading and trailing blanks from `calendar.firstWeekday`), pure and tested in Warsaw and a Sunday-first
  locale.
- `Formatting/`: `DayFormat.monthAndYear(_:calendar:locale:)`, `DayFormat.weekdaySymbols(calendar:locale:)`,
  `MoneyFormat.amount(_:locale:)` (the number without the currency).
- `Features/Calendar/`: `CalendarView` (the sheet), `CalendarViewModel`, `CalendarCell` (presentation:
  day, number text, amount text?, is today, is selected, accessibility label), `CalendarDayCard`
  (presentation for the card), `CalendarPreviewData`.
- `CalendarViewModel(selected:today:workDays:calendar:locale:)`: `monthTitle`, `weekdaySymbols`,
  `weeks: [[CalendarCell?]]`, `quickPicks` (label key, day, is selected), `card`; intents
  `select(_:)`, `showPreviousMonth()`, `showNextMonth()`, `observeMonth() async`, `observeSelectedDay() async`.
- `Features/Today/`: `DayHeaderView` gains the calendar button and an `onShowCalendar` callback, passed
  through `DayView` from `TodayView`; `TodayView` presents the sheet; `TodaySelection.show(_:)`.
- New strings under `calendar.*` and `today.header.calendar`, Ukrainian and English; the counts are catalog
  plurals.

## Changes to other documents

- Product spec, Calendar: the grid shows earnings only on days that earned; the card's three cases; quick
  buttons select.
- `docs/plan.md`: Feature 6's branches.

## Left to the builder

- Cell size, radii, spacing and the card's layout from the `Calendar` artboard, in a `Layout` enum.
- How the grid survives the largest text sizes (a cap on the grid's Dynamic Type, hiding the amount at
  accessibility sizes, or both), as long as nothing clips and VoiceOver still reads the amount.
- Whether the sheet uses detents or opens full height.
- The branch split: logic (`MonthGrid`, the formatters, `CalendarViewModel`, `TodaySelection.show`, tests)
  before UI (the sheet, the header button, the catalog keys), each 300–500 lines.
