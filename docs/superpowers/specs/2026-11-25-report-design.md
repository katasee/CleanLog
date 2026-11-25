# Report and WhatsApp — design

Feature 8 of the roadmap. Product spec: `docs/superpowers/specs/2026-11-13-cleanlog-design.md`
(Report, Report format). Visual reference: the `Report` artboard (the sheet) and the `Stats` artboard
(the «Звіт» button) on the design canvas. Builds on the existing `ReportBuilder`
(`Formatting/ReportBuilder.swift`, Feature 1, tested against the real October report), `MonthStats` and the
`days(in:)` stream of `WorkDayRepository`.

## Intent

At the end of the month the cleaner sends her boss the list of what she cleaned on which day, in the exact
text format the boss already reads. Today she types it by hand from notes. The app already knows every
ticked apartment, so the report should be one tap from the Statistics screen and one more tap into a
WhatsApp chat, with nothing to retype and nothing to get wrong.

## Goals

- A «Звіт» button in the Statistics header that opens the report sheet for the **shown** month.
- The sheet: the title «Звіт за листопад», a subtitle «12 днів · 63 квартири», the report text in a
  monospaced, scrollable card, a large «Надіслати у WhatsApp» button and a round copy button.
- «Надіслати у WhatsApp» opens WhatsApp with the report prefilled (she picks the chat there).
- When WhatsApp is not installed, the large button is «Поділитися» and opens the system share sheet.
- Copy puts the text on the pasteboard and confirms it.
- The text follows the store while the sheet is open.

## Non-goals

- Editing the text in the app: WhatsApp's compose field already lets her change it before sending.
- A saved boss contact or phone number (`whatsapp://send?phone=`): she picks the chat in WhatsApp.
- A report over anything but one calendar month; a header or total line (the format has none).
- The month-end reminder: Feature 9 (Settings and reminders).
- PDF/CSV export (Later in the roadmap).

## Anti-goals

- A report that differs from what the boss is used to — every line comes from `ReportBuilder`, which stays
  tested against the October report.
- A «WhatsApp» button that does something else: when WhatsApp is missing the button says «Поділитися».
- A lost `+`: the report's `+155` must reach WhatsApp as `+`, not as a space (see Sending).

## Decisions taken in the brainstorm (2026-11-25)

1. **A day with only separately reported apartments** (the user's answer, replacing the product spec's
   assumption `5.11-()=0+155`): the line is the date, a dash and the separate names joined by `+`, with no
   brackets and no count:
   - only 155 → `5.11-155`;
   - 155 and 106 → `5.11-106+155` (names in apartment name order, as everywhere in the report).
   A day with at least one counted apartment keeps the existing form `{d}.{M}-(…)={count}+155…`.
2. **The sheet has its own view model that observes the month itself** (the user's choice, approach A):
   `ReportViewModel(month:workDays:…)` subscribes to `days(in: month)` like Statistics and Calendar do,
   instead of Statistics handing over its days. The sheet then works from any screen that can name a month.
3. **WhatsApp is detected up front** (the user's choice, approach S1): `whatsapp` is listed in
   `LSApplicationQueriesSchemes`, the app asks `canOpenURL` once when the sheet opens, and the large button is
   either «Надіслати у WhatsApp» or a `ShareLink` «Поділитися». No UIKit share-sheet wrapper.

Claude's calls (the user may correct them):

4. **The «Звіт» button is disabled on a month with no cleaned apartment** (`StatsSummary.hasCleanedApartments`
   already exists). The sheet itself still handles an empty month (the store can change under it): the card
   shows `stats.empty`'s wording as a report-specific string and both actions are disabled.
5. **The current month's report** holds the days cleaned so far; nothing marks it as unfinished.
6. **Copy feedback:** the copy button's glyph turns into a checkmark (`checkmark`) with a success haptic
   (`sensoryFeedback(.success, trigger:)`) and its accessibility label reads «Скопійовано» for about two
   seconds, then returns. The glyph swap, not a text label, keeps the round 58 pt button the artboard draws.
7. **The title shows the year only for a month of another year than today's** («Звіт за грудень 2025»),
   so a report paged back across New Year is not mistaken for this year's.
8. **The WhatsApp check runs once, in the view model's `init`.** If `openURL` still refuses the link
   (WhatsApp removed while the sheet is open), nothing more happens: copy stays available.
9. **The subtitle** counts working days (days with a cleaned apartment) and cleaned apartments, separate
   ones included — the same numbers as Statistics' «Квартир прибрано» and «N робочих днів», from
   `MonthStats`.

## The sheet

```
┌──────────────────────────────────────┐
│ (×)        Звіт за листопад          │   system toolbar: close (glass on 26), principal title
│         12 днів · 63 квартири        │
│ ┌──────────────────────────────────┐ │
│ │1.11-(100,101,102,103,104,105)=6  │ │   Card, monospaced, scrolls vertically;
│ │                                  │ │   long lines scroll horizontally, never wrap
│ │2.11-(100,101,103,104,106)=5+155  │ │
│ │…                                 │ │
│ └──────────────────────────────────┘ │
│ ( ➤  Надіслати у WhatsApp )   ( ⧉ )  │   accent capsule (glass) · round copy button (glass)
└──────────────────────────────────────┘
```

- Presented from `StatsView` with `.sheet(item:)` over a feature-local route (the month), large detent.
- The title is «Звіт за {month}» with the month in the nominative, lower case in Ukrainian («листопад»);
  English «November report». The builder checks the Foundation form, as Statistics did for «жовтня».
- The text uses `.font(.body.monospaced())` (a Dynamic Type style, not the artboard's fixed 13.5 pt) and is
  selectable (`textSelection(.enabled)`). Lines never wrap: a wrapped line reads as two days.
- The action row sits below the card, outside the scroll view, so it is always on screen.
- Accessibility: the copy button is icon-only and has a label («Копіювати звіт» / «Скопійовано»); the report
  card reads as one element labelled «Текст звіту».
- New strings under `report.*`, Ukrainian and English; «N днів» and «N квартир» are plurals.

## Sending

- **The link** is `whatsapp://send?text=<the report, percent-encoded>`. `URLComponents.queryItems` leaves `+`
  unencoded, and WhatsApp decodes `+` as a space, so the text is encoded with the URL-unreserved characters
  only (`A–Z a–z 0–9 - . _ ~`); `+`, `=`, `,`, `(`, `)` and the newlines all become `%XX`. The link builder is a
  pure, tested function (`+155` → `%2B155`, `\n` → `%0A`).
- **Detection** goes through a small protocol (`canOpen(_ url:) -> Bool`) given to the view model, with the
  `UIApplication.canOpenURL` implementation built in `AppDependencies` and a fake in tests. The view model
  exposes the send action as presentation state (a WhatsApp link, or the text to share), never `UIApplication`.
- **Opening** the link is the view's `openURL` environment action; the share fallback is SwiftUI's
  `ShareLink(item: text)`.
- **Copying** goes through a pasteboard protocol (`UIPasteboard.general` in `AppDependencies`, a fake in tests),
  called by the view model's copy action.
- **`LSApplicationQueriesSchemes`** cannot be set through a generated-Info.plist build setting (it is an
  array), so the target gets a partial Info.plist holding only that key, merged with the generated one. It
  lives outside the synchronized `CleanLog/` folder (or is excluded from its membership), or the build copies
  it twice.

## Changes to existing code

- `ReportBuilder.line(for:)`: decision 1. The test `printsADayWithOnlySeparateApartments` changes to
  `5.11-155`, and a new one covers two separate apartments. The October test is untouched.
- `StatsView`: a «Звіт» toolbar button (the artboard's share glyph, `square.and.arrow.up`), disabled per
  decision 4, presenting the sheet for `viewModel.shownMonth`.
- `AppDependencies`: the WhatsApp-detection and pasteboard implementations, handed to `StatsView` for the
  sheet's view model.
- Product spec: Report section and Report format updated to decisions 1, 3 and 4.

## Testing

- `ReportBuilder`: the October report, a day with only one and with two separate apartments.
- The link builder: the percent-encoding above, against a two-line report with `+155`.
- `ReportViewModel` against `FakeWorkDayRepository` and the fakes: text, title, subtitle (plurals via the
  catalog), the empty month, WhatsApp present vs absent, copy writes the exact text and sets the copied state,
  the text follows a store change while observing. `now`, `Calendar` and `Locale` pinned.

## Left to the builder

- How the copied state returns after two seconds without a stored `Task` in the view model (the plan review
  with `swift-concurrency-pro` settles it).
- File names and the split into branches (logic first, then UI).
- The exact Foundation call for the nominative month in the title.
