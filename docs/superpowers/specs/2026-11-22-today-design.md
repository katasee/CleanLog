# Today — design

Feature 4 of the roadmap. Product spec: `docs/superpowers/specs/2026-11-13-cleanlog-design.md`
(Today, A future day, A past day). Visual reference: the `Main` (today, timer running),
`TodayEmpty` (start of the day) and `PastDay` artboards on the design canvas.

## Intent

The Today tab is the screen the cleaner lives in during a working day: she starts the timer when she
arrives, ticks each apartment off as she finishes it, sees what she has earned today and this month,
and stops the timer when she goes home. The same screen, stepped back with ‹, is where she fixes a
day she forgot to tick or to time; stepped forward with ›, it shows a day planned ahead. Ticking must
stay one tap, and nothing on the screen may be a button that leads nowhere.

## Goals

- One screen for today, any past day and any future day, switched with ‹ › in the header.
- The work timer with start, pause, resume and stop, surviving the app being killed (the stored state
  is timestamps, already in `WorkDay+Timer`).
- Today's earned / planned sum with a progress bar, and the month's total and cleaned count.
- The day's apartments: tap to tick, swipe to remove from the day.
- An empty day offers «Як учора · N квартир»: copy the most recent earlier day's plan, unticked.
- A past day shows its total time with a span line and lets the time be set by hand.

## Non-goals (this feature)

- **The Day plan sheet** and every button that opens it: the empty state's «Додати квартири» and the
  list's «+ Додати квартиру» row (on every day since 2026-11-24; the floating add button was dropped). They arrive with Feature 5, together
  with the sheet (the user's decision, 2026-11-22: no button without its screen). Until then a fresh
  install cannot make its first plan; the app is handed to the user after Feature 5.
- **The calendar button and sheet** — Feature 6.
- A Live Activity, a timer per apartment, notifications.

## Anti-goals

- Ticking that takes more than one tap or asks for confirmation.
- A stray tap on «Стоп» that loses the day's timing with no way back.
- A forgotten timer adding a whole night (or days) of work to the month.
- «Як учора» bringing back an apartment deleted from the template since that day.
- A screen that silently stays on yesterday after midnight while it says «Сьогодні».

## Decisions taken in the brainstorm (2026-11-22)

1. **Today first, without the Day plan and calendar buttons** (above).
2. **«Стоп» finishes the day at once, with no confirmation.** The timer card then shows the day's
   total and span line, like a past day, and a «Продовжити» button that starts a new session
   (`startingTimer` already allows it after `finished`). A wrong tap is undone with one tap.
3. **One view model per shown day** (approach 1, below).
4. **The timer stops by itself when the last apartment is ticked** (the user's rule): ticking the day's
   last unticked entry today, while the timer runs or is paused, finishes the timer at the tick's
   time, exactly like «Стоп». Unticking later does not restart it; «Продовжити» does.
5. **A timer that runs into the next day records no time for its day** (the user's rule): when a day
   before today still has an open session, all of that day's sessions are dropped — not only the
   open one — and the day keeps its ticks and earnings but has no recorded time, so it does not skew
   the earnings per hour. The cleaner does not work past midnight (confirmed), so no real day loses
   time this way. That past day's timer card shows `0:00` with «Час не записано — таймер не
   зупинили», and «Змінити» lets her enter the time by hand.
6. Proposed by Claude and accepted without change:
   - «Сьогодні» follows the clock: when the app comes back to the foreground or midnight passes
     while the screen shows today, it moves to the new today. A screen showing another day
     stays on it.
   - A past day's timer card: the total, then a span line «07:30 – 13:05 · пауза 25 хв» — the first
     session's start, the last session's end, and the sum of the gaps between sessions; without gaps
     only «07:30 – 13:05»; with a manual duration or no sessions, no span line. «Змінити» opens an
     hours-and-minutes picker with «Скинути», which clears the manual duration and returns to the
     sessions' sum.
   - A past day has one summary card, «Заробіток за день», instead of the two (canvas).
   - A future day has no timer card at all and its rows cannot be ticked; swipe to remove works.
   - Removing an apartment from the day is a swipe with no confirmation: the template keeps it.

## Approaches considered

| | Approach | Trade-off |
|---|---|---|
| **1 (chosen)** | `TodayView` keeps only the selected `DayKey`; the day's content is a child view with its own `DayViewModel`, given `.id(day)`, subscribing in its `.task` | each view model knows one day, so its tests and state are simple; stepping a day rebuilds the child and SwiftUI cancels the old stream; no stored `Task`, as `architecture.md` requires |
| 2 | One `TodayViewModel` with `select(_:)` restarting its subscriptions | needs a stored `Task` or a stream of selected days inside `observe()`; more state, against the conventions |
| 3 | Swipe between days as pages | not in the design, and the page swipe fights the row's swipe-to-remove |

## The screen

```
  ‹  П'ятниця, 13 листопада  ›            (today: subtitle = weekday, date)
  Сьогодні                                 (past/future: title = date, subtitle = weekday · минулий/майбутній день,
                                            and a «Сьогодні» glass button on the right)
 ┌──────────────────────────────────────┐
 │ ● Працюю · з 07:40          (⏸) (■)  │  timer card (today only; hidden on a future day)
 │ 4:12:35                               │
 └──────────────────────────────────────┘
 ┌────────────────┐ ┌───────────────────┐
 │ Сьогодні        │ │ Листопад          │  today: two cards; past: one «Заробіток за день»;
 │ 112 / 224 zł    │ │ 1 988 zł          │  future: one «Заплановано» card
 │ ▓▓▓▓▓░░░░░      │ │ 63 квартири       │
 └────────────────┘ └───────────────────┘
  Квартири                    4 з 7 прибрано
 ┌──────────────────────────────────────┐
 │ (✓) 100                      🔑 4821 │  tap = tick (today, past); swipe = remove
 │ ( ) 106  окремо              🔑 7409 │
 └──────────────────────────────────────┘
```

### Header

- Today: subtitle «П'ятниця, 13 листопада» (weekday and date, localized template), title «Сьогодні».
- Another day: title «12 листопада», subtitle «Четвер · минулий день» or «Субота · майбутній день»,
  and a «Сьогодні» button (glass) that jumps back. ‹ and › step one day, any number of days back or
  forward; both are icon buttons with accessibility labels and 44 pt targets.

### Timer card (today)

| State | Shows | Buttons |
|---|---|---|
| idle | «Робочий час», `0:00:00` in `InkSecondary` | «Почати» |
| running | `Accent` dot, «Працюю · з 07:40» (start of the first session), the elapsed time ticking | pause, stop |
| paused | `Warning` dot, «Пауза», the elapsed time, still | resume, stop |
| finished | «Робочий час», the total, the span line | «Продовжити» |

Finished is reached by «Стоп» or by ticking the last apartment (decision 4).

The elapsed time is `workedDuration(now:)` over all sessions, formatted with `DurationFormat.clock`,
redrawn every second by a `TimelineView`; the view model gives the text for a given `now`, the view
never formats. Large numbers use `.largeTitle`, rounded, monospaced digits.

### Timer card (past day)

«Робочий час», the total (`DurationFormat.short`), the span line, «Змінити». A past day with no time at
all shows `0:00` and «Змінити»; one whose overrun timer was dropped (decision 5) adds the line «Час не
записано — таймер не зупинили». After the drop there is never an open session on a past day.

### Summary cards

- Today: «Сьогодні» `earned / planned zł` with a progress bar on `AccentSoft` (hidden text «ще немає
  квартир» and no bar when nothing is planned); the month card: the month name, its earned total
  and «N квартир» (catalog plurals) — the month of the shown day, over `days(in:)`.
- Past day: one card, «Заробіток за день · N zł».
- Future day: one card, «Заплановано · N zł».

### Apartment list

- A section header «Квартири» with «4 з 7 прибрано».
- A row: check circle (filled `Accent` with a white checkmark when cleaned), the name, an «окремо»
  badge when the entry is reported separately, and the access code with a key glyph from the
  template apartment (an entry snapshot has no code; no code → nothing on the right). Rows keep the
  order they were planned in.
- Tap ticks / unticks (today and past days); on a future day the row is not a button.
- Swipe → «Прибрати» removes the entry from the day (no confirmation; the CL-15 lesson applies: no
  `role: .destructive` on the swipe button, the `Destructive` colour instead).
- A tick plays `sensoryFeedback(.success)`.

### Empty state (any day with no entries)

An icon on an `AccentSoft` circle, «Які квартири сьогодні?» (past and future days: «Квартир на цей
день немає»), and «Як учора · N квартир» when there is an earlier day with entries that still has at
least one apartment in the template. N is the count after that filter. No button otherwise —
the app does not search further back for an older day (Claude's call: a rare case, and a search
would change the repository in three places).

## Logic and where it lives

- `Models/`:
  - `WorkDay.copyingPlan(from:template:)` — the copy, keeping only entries whose apartment is still in
    the template, and building each new entry from the **current** template apartment
    (`DayEntry(planning:)`), so a changed price, name or report flag applies — "a price change
    applies to new entries only", and a copied entry is new (Claude's call). `copyingPlan(from:)` and
    `DayEntry.replanned()` go if nothing else uses them.
  - Ticking with the auto-stop: a `WorkDay` function that sets the entry cleaned and, when it was the
    last unticked one, today, and the timer is running or paused, finishes the timer at the same
    `now` — one write, so the tick and the stop cannot come apart.
  - `WorkDay.droppingOverrunTimer(today:)` — for a day before `today` with an open session, removes
    every session and marks the day as having had its time dropped (a stored flag, e.g.
    `isTimeDropped`, cleared when a manual duration is set; the record gets a defaulted attribute,
    CloudKit-compatible). Any other day is returned unchanged.
  - `WorkDay.timeSpan` → `WorkSpan?` (`start`, `end`, `pauses: Duration`) — nil with no sessions or a
    manual duration; `end` is nil while a session is open.
  - `DayKey.relation(to today:)` → `.past / .today / .future` if the view model needs more than `<`.
- `Formatting/`: the header date and weekday (templates, `Locale.current`), the clock time «07:40»
  (localized hour-minute template), the pause «25 хв» (`Duration` units style).
- `Features/Today/`:
  - `TodayView` — the selected day and today; the header; the midnight refresh (the scene phase, and a
    `.task` that sleeps until the next day starts); the child `DayView(day:).id(day)`.
  - `DayViewModel` (`@Observable @MainActor final`) — init with `day`, `today` (or a clock closure),
    `calendar`, `WorkDayRepository`, `ApartmentRepository`; `observe()` iterates the day stream, the
    month stream and the template stream (three loops in a task group or `async let`); exposes
    presentation state (`header`, `timer`, `summary`, `rows: [DayRow]`, `copyOffer`, error flag and
    message) and intents (`toggle(_:)`, `remove(_:)`, `startTimer()`, `pauseTimer()`,
    `resumeTimer()`, `finishTimer()`, `copyPlan()`, `setManualDuration(_:)`, `timerText(at:)`).
    Every write goes through `repository.update(day) { try $0.… }`; a thrown error becomes the
    localized alert, never swallowed.
  - The overrun drop is a write, so what is stored is what every screen reads (Statistics, Report and
    Calendar never need to know about it). It runs when the Today screen shows today — the launch
    tab, so before anything else reads time — on launch, on return to the foreground and on a day
    change, over every earlier day with an open session. That needs a repository read for such days
    (e.g. `daysWithOpenSession(before:)` on the protocol, the fake and the SwiftData repository, with
    contract tests). Where exactly it runs (the day view model for today or a small type of its own
    that `TodayView` builds) is the plan's call.
  - The "as yesterday" source is `latestDayWithEntries(before: day)`, read again whenever the day or
    the template changes while the day is empty.
- Strings: every key in `Localizable.xcstrings` under `today.*`, Ukrainian and English, plurals for
  «N квартир».

## Testing

Test-first: the new `Models/` and `Formatting/` functions (pinned `Calendar`, `Locale`, Warsaw time
zone), and `DayViewModel` against `FakeWorkDayRepository` / `FakeApartmentRepository` — each timer
state's text and buttons, ticks refused on a future day, the copy filter and its count, the
summary per day kind, a refused write surfacing the error, the timer text for a pinned `now`.

## Branch split (estimate for the plan)

Logic first, no SwiftUI view in its diff; then UI on a tested view model.

1. Domain and formatting: copy filter, tick with auto-stop, overrun drop, time span, day relation,
   header / time / pause formatters.
1b. Repository: the open-session read, the stored drop flag, contract tests (may join 1 if small).
2. `DayViewModel`: state and presentation (header, rows, summaries, timer texts).
3. `DayViewModel`: intents (ticks, remove, timer, copy, manual duration) and errors. 2 and 3 may be
   one branch if it stays under 500 lines.
4. UI: `TodayView` header and day stepping, the timer card, summary cards, the list.
5. UI: empty state, past / future variants, the manual-duration picker, the midnight refresh.

## Left to the builder

Exact paddings and radii (take them from the canvas into each view's `Layout`), the backdrop circles
per day kind (Today's existing ones for all, unless the past day's canvas placement is cheap), the
picker's control (a `DatePicker` in countdown mode is not available in SwiftUI; two wheel `Picker`s
or a `.hourAndMinute` duration field), and how the three streams are joined inside `observe()`.
