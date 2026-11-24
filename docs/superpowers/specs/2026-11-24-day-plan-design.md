# Day plan — design

Feature 5 of the roadmap. Product spec: `docs/superpowers/specs/2026-11-13-cleanlog-design.md`
(Day plan). Visual reference: the `AddSheet` artboard on the design canvas. Builds on Today
(`docs/superpowers/specs/2026-11-22-today-design.md`), which left every button that opens this sheet
out until the sheet exists.

## Intent

The cleaner puts apartments on a day: in the morning for today, the evening before for tomorrow, or
afterwards for a past day she forgot to log. She picks them from her template by tapping tiles, sees
what the day will be worth, and confirms once. An apartment she has never cleaned before is created on
the spot without leaving the sheet. Until this feature lands, a fresh install cannot make its first
plan, so it is the last thing before the app goes to the user.

## Goals

- A sheet that adds apartments from the template to one day, several at a time.
- It shows only the template apartments **not yet on the day**; what is already planned stays on the
  day screen.
- A search field that filters the tiles by name.
- **«Нова»** creates an apartment in the template and puts it into the selection.
- One confirm button that names the count and the sum: «Додати 7 квартир · 224 zł».
- Every way into the sheet: the empty day's «Додати квартири» and a «+ Додати квартиру» row at the end of
  the day's apartment list, on today, a past day and a future day alike.

## Non-goals

- **Removing apartments in the sheet.** Removal stays the swipe on the day screen (the user's decision,
  2026-11-24).
- **The floating add button beside the tab bar** — dropped from the product (the user's decision,
  2026-11-24). The list's «+ Додати квартиру» row replaces it.
- Editing or deleting template apartments from the sheet; that is the Apartments tab.
- Reordering the day's entries.

## Anti-goals

- A tap in the sheet that changes the day before the confirm button: closing with ✕ leaves the day as
  it was.
- The same apartment twice on a day.
- An apartment created with «Нова» that the cleaner then has to find and tap again.
- A tile grid that clips or overlaps at the largest Dynamic Type size.

## Decisions taken in the brainstorm (2026-11-24)

1. **No floating add button.** The product spec loses it; the entry point on a day that already has
   apartments is a «+ Додати квартиру» row at the end of the list, on every kind of day (Claude's
   proposal, accepted). The past day's row in the Today spec becomes this row.
2. **The sheet only adds.** Apartments already on the day are not shown; when every template apartment is
   on the day, only «Нова» is left, with the line «Усі квартири вже додані».
3. **The sheet has its own view model** (approach 1, below).
4. **«Нова» returns into the selection** (Claude's proposal, accepted): the apartment form opens over
   the sheet; its save writes the apartment to the template, and the sheet comes back to the grid with
   the new apartment selected. It reaches the day with the rest on confirm. Closing the sheet with ✕
   after that keeps the apartment in the template and leaves the day unchanged.
5. **Adding to a finished today leaves the timer finished** (the user's decision): when the last tick
   has stopped today's timer and the sheet then adds apartments, the timer card keeps showing the day's
   total and «Продовжити». A timer that started by itself could run past midnight unnoticed (a late
   apartment logged from home) and the overrun rule would then drop the whole day's time. The write
   stays plain `planning`; no timer rule changes.

## Approaches

| # | Approach | Trade-off | Verdict |
|---|---|---|---|
| 1 | `DayPlanViewModel` owned by the sheet: observes the template and the day, holds the selection and the search, writes on confirm | one more view model; the sheet tests on fakes without the day screen | **chosen** |
| 2 | The sheet hands the selection back to `DayViewModel`, which writes | one writer per day, but `DayViewModel` (already the largest type) takes search and selection too | rejected: two reasons to change one type |
| 3 | The sheet reads the template with `@Query` | — | ruled out: SwiftData stays inside `Persistence/` |

## The sheet

```
 ✕          Додати на сьогодні           ✓
 ┌──────────────────────────────────────┐
 │ 🔍  Номер квартири                   │
 └──────────────────────────────────────┘
 Мої квартири                    обрано 2
 ┌──────┐ ┌──────┐ ┌──────┐
 │ 103  │ │▓104▓▓│ │ 105  │      tap = select / deselect
 │28 zł │ │▓28 zł│ │28 zł │
 └──────┘ └──────┘ └──────┘
 ┌──────┐ ┌ ─ ─ ─┐
 │▓106▓▓│ │  ＋   │              «Нова» → the apartment form
 │▓56 zł│ │ Нова │
 └──────┘ └ ─ ─ ─┘

 [      Додати 2 квартири · 84 zł      ]
```

- **Title**: «Додати на сьогодні» for today, «Додати на 12 листопада» for any other day (the date through
  a `Formatting/` template formatter, like the day header).
- **✕** dismisses without writing. **✓** in the toolbar and the bottom button do the same thing: confirm.
- **Tiles**: template apartments not on the day, in the template's order (`ApartmentNameOrder`), each with
  its name and price (`MoneyFormat`). A selected tile is filled with `AccentColor`; it is a toggle with
  the selected trait for VoiceOver. The grid is adaptive: three columns at default sizes, fewer as text
  grows (Claude's call).
- **«Обрано N»** counts the selection (a catalog plural); hidden when nothing is selected.
- **Search** filters the tiles by name, case-insensitive, containing the text. A selected tile hidden by
  the filter stays selected and still counts in the button. With no match: «Нічого не знайдено», and
  «Нова» opens with the name pre-filled from the search text (Claude's call).
- **Confirm button**: «Додати N квартир · S zł» (a plural), the sum of the selected apartments' current
  template prices — the price the new entries will carry. Disabled with «Обери квартири» when nothing is
  selected (Claude's call).
- **Empty template** (a fresh install): only «Нова», with «Створи першу квартиру» above it (Claude's call).
- A future day and a past day get the same sheet: planning is allowed on any day; ticking rules stay on
  the day screen.

## Behaviour

- **One write on confirm**: `workDays.update(day) { $0.planning(selected) }` with the selected apartments
  in template order. `planning` already skips an apartment that reached the day in the meantime, so a
  second device or a fast double tap cannot duplicate it.
- On success the sheet dismisses. On a save error the sheet stays open with an alert (the view model's
  localized message) and keeps the selection, so a retry is one tap (Claude's call; unlike the manual
  duration sheet, this view model owns its write).
- The view model observes both streams while the sheet is open. An apartment that lands on the day
  (elsewhere) or leaves the template disappears from the tiles and from the selection; a price change
  updates the tile and the sum.
- **«Нова»** presents the apartment form exactly as the Apartments tab does — a full-screen cover, here
  over the sheet — so the form keeps its own backdrop, animation and Cancel / Save buttons and needs no
  rework (Claude's call, after the builder check: pushing it would mean a second layout of the form).
  The form's view model must hand back the created `Apartment` (today `save()` returns `Bool` and drops
  it); the sheet's view model then adds its ID to the selection. The template stream brings the tile itself.

## Code shape

- `Features/DayPlan/`: `DayPlanView` (the sheet), `DayPlanViewModel`, `DayPlanTile` (presentation model:
  id, name, price text, is selected), `DayPlanPreviewData`.
- `DayPlanViewModel(day:today:apartments:workDays:)` — protocols in, presentation out: `title`, `tiles`,
  `searchText`, `selectedCountText`, `confirmTitle`, `canConfirm`, `emptyMessage`, `errorMessage`;
  intents `toggle(_:)`, `select(_:)` (after «Нова»), `confirm() async -> Bool`, `observe() async`.
- **The apartment form becomes shared.** `ApartmentFormView` and `ApartmentFormViewModel` are now used by
  two features. They hold a repository and SwiftUI, so they fit neither `Models/` nor `UICommons/`: they
  move to their own feature folder `Features/ApartmentForm/`, and `architecture.md`'s feature list gains
  it (Claude's call; the convention gets the rule "a screen used by two features is its own feature").
- **Entry points** on `DayView`: the empty day's «Додати квартири» button and the list's last row present
  the sheet. `DayView`'s two sheets (manual duration, day plan) become one optional enum with one
  `.sheet(item:)`, as `architecture.md` asks.
- New strings under `dayPlan.*` and `today.list.add`, `today.empty.add`, Ukrainian and English.

## Changes to other documents

- Product spec: the floating add button goes from Screens; Day plan says the sheet shows only apartments
  not on the day, and «Нова» returns selected.
- Today spec: the past-day «+ Додати квартиру» row is now on every day.
- `docs/plan.md`: roadmap item 5 loses the floating button.

## Left to the builder

- The tile's exact size, corner radius and spacing (from the `AddSheet` artboard, in a `Layout` enum).
- Whether the toolbar ✓ is shown at all on iOS 18 next to the bottom button.
- The branch split: logic (the form move, `DayPlanViewModel` and its tests) before UI (the sheet, the
  entry points), each 300–500 lines.
