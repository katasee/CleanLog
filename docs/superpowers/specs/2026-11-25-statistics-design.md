# Statistics — design

Feature 7 of the roadmap. Product spec: `docs/superpowers/specs/2026-11-13-cleanlog-design.md`
(Statistics). Visual reference: the `Stats` artboard on the design canvas. Builds on the existing
`MonthStats` calculator (`Models/MonthStats.swift`, Feature 1) and the `days(in:)` stream of
`WorkDayRepository`.

## Intent

The cleaner wants to see at a glance what a month earned her and how long she worked for it: the total,
whether it went up or down against the month before, how much an hour of her work is worth, and which
apartments make up most of it. The screen is read-only; every number follows from what she ticked and
timed on the day screen.

## Goals

- A Statistics tab with a month switcher (‹ «Листопад 2026» ›), opening on the current month.
- The month's earnings as one large number.
- A change badge against the previous month («↑ 9% до жовтня») on a **finished** month.
- Four cards: «Квартир прибрано», «Робочий час», «За годину», «Середньо за день».
- «Найчастіші квартири»: the top three with a proportional bar and «N разів», and the month's working-day
  count («12 робочих днів») beside the heading.
- Every number follows the store: ticking an apartment or finishing the timer updates the screen at once.

## Non-goals

- The «Звіт» button: it opens the report sheet, which is Feature 8, and arrives with it.
- Charts (removed from the product in the design review).
- Months after the current one: › is disabled on the current month.
- Statistics over a custom range, a year, or a week.

## Anti-goals

- A badge that alarms her for no reason: comparing a month in progress with a whole previous month shows a
  drop every first fortnight. Hence decision 1.
- An hourly rate that jumps while she works: today's time with the timer still running (or paused) would
  divide today's earnings by a part of the day. Hence decision 2.
- A sum that differs from the day screen's or the calendar's: everything is `WorkDay.earned`.
- Totals that depend on the device locale: `MonthStats` returns `Money`, `Int` and `Duration`; only the
  presentation model formats.

## Decisions taken in the brainstorm (2026-11-25)

1. **The badge shows only on a finished month** (the user's choice, option C). On the current month it is
   hidden. On a finished month it compares the month's earnings with the previous month's whole earnings:
   - the previous month earned zero → hidden (product spec);
   - this month earned zero → hidden (the user's choice after the builder check: «0 zł» already says it,
     «↓ 100%» only alarms);
   - more → «↑ 9% до жовтня», less → «↓ 12% до жовтня», equal (or rounding to 0) → «0% до жовтня» with no arrow;
   - the percentage is `|this − previous| / previous`, rounded half up to a whole percent, in integer arithmetic.
2. **A day's time counts only once its work is over** (the user's choice, 2026-11-25, instead of a
   per-minute refresh). A day contributes worked time when:
   - it has a manual duration (always counts), or
   - it is before today, or it is today with the timer finished — then its closed sessions count;
   - a past day that still has an open session counts nothing (Claude's call after the builder check): the
     day screen's `droppingOverrunTimer` clears all of that day's sessions, so Statistics shows now what the
     stored day will hold once the drop is saved, and no number appears only to vanish.
   Today with the timer running or paused contributes no time, so it is a day without recorded time: its
   earnings stay in «Заробіток» and «Середньо за день» but not in «За годину». No timer ticks on this
   screen.
3. **The month switcher** (Claude's proposal, accepted): ‹ goes back without limit; › is disabled on the
   current month; the tab opens on the current month.
4. **«Робочий час»** (accepted): hours and minutes, «62 год, 15 хв» (Foundation's abbreviated form); whole hours read
   «62 год»; zero reads «0 год».
5. **An empty month** (accepted) is a month with no cleaned entry. The cards always show the real numbers
   (a month with only manual time shows that time), so a month with nothing at all reads «0 zł», «0», «0 год»,
   «—» for «За годину» and «Середньо за день», and no badge. The only thing emptiness changes: instead of the
   apartment list, one line «Цього місяця ще нічого не прибрано» (Claude's call after the builder check).
6. **The bars** (accepted): the most frequent apartment's bar is full, the others proportional to it;
   «N разів» is a catalog plural.

## Approaches

**The previous month's earnings for the badge:**

| # | Approach | Trade-off | Verdict |
|---|---|---|---|
| 1 | The view model observes `days(in: shown)` and `days(in: shown.previous)` side by side | no protocol change; both numbers follow edits; both restart per month | **chosen** (user) |
| 2 | A new repository read `days(from:through:)` returning both months in one stream | one stream, but a protocol change, a SwiftData query, a fake and their tests for no other caller | rejected |

**Today's running time:**

| # | Approach | Trade-off | Verdict |
|---|---|---|---|
| 1 | A per-minute ticker in the view model | live hours, but the hourly rate moves while she works | rejected |
| 2 | `TimelineView(.everyMinute)` in the view | less code, but the view decides when to recompute | rejected |
| 3 | Count a day's time only when its work is over (decision 2) | no ticker at all; the rate is stable | **chosen** (user) |

## The screen

```
 Статистика
 ‹  Листопад 2026  ›
 ┌──────────────────────────┐
 │ Заробіток                │
 │ 2 016 zł                 │
 │ [↑ 9% до жовтня]         │   finished months only
 └──────────────────────────┘
 ┌────────────┐ ┌────────────┐
 │ Квартир    │ │ Робочий    │
 │ прибрано 63│ │ час 62 год │
 ├────────────┤ ├────────────┤
 │ За годину  │ │ Середньо   │
 │ 33 zł      │ │ за день    │
 └────────────┘ └────────────┘     168 zł
 Найчастіші квартири   12 робочих днів
 ┌──────────────────────────┐
 │ 100  ██████████  10 разів│
 │ 102  ██████████  10 разів│
 │ 101  █████████    9 разів│
 └──────────────────────────┘
```

- **Title** «Статистика» as the navigation title (large).
- **Month switcher**: a glass capsule with ‹, the month title and ›, each arrow a 44 pt target with an
  accessibility label («Попередній місяць», «Наступний місяць»); › disabled on the current month.
  The title uses the calendar's month-and-year formatter (`DayFormat.monthAndYear`).
- **Earnings card**: «Заробіток» caption, the amount in `.largeTitle`, `.fontDesign(.rounded)`,
  `.monospacedDigit()`; the badge under it on `AccentSoft` with `AccentColor` text. The card reads as one
  VoiceOver element.
- **Four cards** in a two-column grid on `.cardSurface()`, caption and value; each reads as one element.
- **Top apartments**: the heading with the working-day count (a catalog plural), then a card of up to three
  rows: name, bar (`AccentSoft` track, `AccentColor` fill; hidden from VoiceOver), «N разів». A row reads
  «100, 10 разів».
- The screen scrolls; at accessibility text sizes the card grid becomes one column (Claude's call; the
  builder picks the mechanism).

## Behaviour

- `StatsViewModel` observes the shown month and the previous month side by side (approach 1), as two
  observations (`observeMonth()`, `observePreviousMonth()`), each in its own `.task(id: shownMonth)` — the
  shape `CalendarViewModel` already uses. Changing the month restarts both. A yield for a month that is
  no longer shown is ignored, as in `CalendarViewModel`.
- The current day comes from the view: `today` is fixed when the view model is built and refreshed when the
  app returns to the foreground (Claude's call; a midnight passing with the app open only delays the
  current-month check until the next foreground). The view model gains `advance(to today:)`; if the shown
  month was the current month and the month rolled over, the screen stays on the shown month.
- The badge needs the previous month's earnings only; the previous month's other numbers are not shown.

## Code shape

- `Models/MonthStats.swift`: `calculate(days:today:)` replaces `calculate(days:now:)` and applies decision 2
  through a new pure `WorkDay.countedDuration(today:) -> Duration?` (in `WorkDay+Timer.swift`; `nil` when the
  day contributes no time). `DaySummary` (Today) switches to the new signature; it uses only `earned` and
  `cleanedCount`.
- `Models/`: `EarningsChange` — `calculate(current:previous:) -> EarningsChange?`: `nil` when previous is
  zero; otherwise a direction (up, down, same) and a whole percent. Pure, tested on the rounding edges.
- `Formatting/`: `DurationFormat.hoursAndMinutes(_:locale:)` for «62 год, 15 хв» / «62 год» / «0 год»;
  the month name in the badge from the locale («до жовтня» is a catalog string with the month as an
  argument — the genitive form is the builder's to get right, see below).
- `Features/Stats/`: `StatsView`, `StatsViewModel`, `StatsSummary` (presentation: earned text, badge
  text and direction?, four card values, top rows, working-days text, `isEmpty`), `StatsApartmentRow` (name,
  count text, bar fraction; the row reads as one combined element), `StatsPreviewData`.
- `StatsViewModel(today:workDays:calendar:locale:)`: `monthTitle`, `canShowNextMonth`, `summary`;
  intents `showPreviousMonth()`, `showNextMonth()`, `advance(to:)`, `observeMonth() async`,
  `observePreviousMonth() async`.
- `App/RootView`: builds `StatsView` with the dependencies, as the other tabs do.
- New strings under `stats.*`, Ukrainian and English; «N разів», «N робочих днів» are plurals.

## Changes to other documents

- Product spec, Statistics: the badge only on finished months; time counted once a day's work is over; the
  «Звіт» button moves to the Report feature.
- `docs/plan.md`: Feature 7's branches; the Calendar plan file is deleted in this feature's first branch.

## Left to the builder

- Sizes, radii and spacing from the `Stats` artboard, in a `Layout` enum.
- The badge's month wording in Ukrainian: «до жовтня» needs the month in the genitive after «до». Either a
  formatter that yields it (Foundation's `MMMM` in a day context gives «жовтня») or the catalog — whichever
  is correct in both languages («vs October» in English).
- How the grid collapses at large text, as long as nothing clips.
- The branch split: logic (`countedDuration`, `MonthStats` change, `EarningsChange`, the duration formatter,
  `StatsSummary`, `StatsViewModel`, tests) before UI (the screen, the catalog keys, `RootView`), each
  300–500 lines.
