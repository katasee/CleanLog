# Apartments (template) — design

Feature 3 of the roadmap. Product spec: `docs/superpowers/specs/2026-11-13-cleanlog-design.md`
(Apartments section). Visual reference: the `Apartments` artboard on the design canvas.

## Intent

The Apartments tab is the template the cleaner plans every day from: the apartments she cleans, each
with its price, an optional access code and whether it goes to the report separately. She fills it once
on the first launch and touches it rarely after that (a new apartment, a price change, one she no longer
cleans). It has to be obvious to a first-time user with large text, and nothing done here may change a
past month.

## Decisions taken in the brainstorm (2026-11-21)

1. **No archive — an apartment is deleted.** Archiving was the original guard against losing history,
   but every `DayEntry` already copies the apartment's name, price and report flag when it is planned,
   and the report and statistics read only those copies. Deleting an apartment therefore leaves every
   past day and report as it was. `isArchived`, `apartments(includingArchived:)` and `archive(_:)` go
   away; the repository gets `delete(_:)`.
2. **No manual order — apartments are always sorted by name, ascending**, by one rule (below). The
   same order is used by the Apartments list, the brackets of the report and, later, the Day plan grid.
   `reorder(_:)`, `Apartment.sortOrder`, `Apartment.nextSortOrder(after:)` and `DayEntry.sortOrder` go
   away.
3. **The form is a compact sheet from the bottom** (half height, can be dragged to full height so it
   still fits the largest text sizes), the same sheet for a new apartment (`+`) and for editing (tap a
   row, fields prefilled).
4. **Delete is a swipe on the row only**, always confirmed. There is no delete button in the form.
5. **Empty state**: an icon, «Додай свої квартири» and a «Додати квартиру» button that opens the same
   sheet. The `+` in the toolbar works too.
6. **No Settings button yet.** It appears with Feature 9; a button that leads nowhere is dead UI.

## The name order

`ApartmentNameOrder` (in `Models/`), a pure comparison over two names:

1. Names made only of the digits 0–9 come first, compared as numbers: `54, 64, 96, 100, 105`.
2. Every other name comes after them, compared with numeric, case-insensitive string comparison that
   does not depend on the device locale: `6piw, 133kol`.

Checked against the real October report: every line comes out as the boss's text
(`2.10-(54,64,96,105,115,138,6piw)=7+155`). Two names that compare equal (`054` and `54`) fall back to
plain string order so the result is stable. Names are unique case-insensitively, so this is the only
tie.

## Screen

```
┌──────────────────────────────┐
│                          [+] │  toolbar, system glass on iOS 26
│ Квартири                     │  large navigation title
│ 7 квартир                    │  count, a catalog plural
│ ┌──────────────────────────┐ │
│ │ 100              28 zł › │ │  name · price · chevron
│ │ 106 [окремо у звіті] 56 zł › │  badge on AccentSoft
│ └──────────────────────────┘ │  rows on Card
│ Нова ціна діє лише для       │  footnote, InkSecondary
│ наступних прибирань — минулі │
│ місяці не змінюються.        │
└──────────────────────────────┘
```

- Rows show name, price (`MoneyFormat`) and the «окремо у звіті» badge. The access code is not shown
  here; it matters on the Today rows.
- Tap a row → the edit sheet. Swipe left → «Видалити» → a confirmation: title «Видалити 106?»,
  message «Минулі прибирання лишаться у звітах.», a destructive «Видалити» and «Скасувати».
- A row reads as one accessibility element ("106, 56 zł, окремо у звіті").

### The sheet

```
Скасувати        Нова квартира        Зберегти
Назва           [106            ]
Ціна            [56             ] zł
Код доступу     [4821           ]   (optional)
Окремо у звіті  [ on ]
```

- Title «Нова квартира» or the apartment's name when editing.
- Price is typed in złoty with an optional fraction: `28`, `28,50` and `28.50` are accepted; more than
  two fraction digits, letters or a minus are not. A decimal keyboard. When editing, the field shows the
  stored price without `zł`, with the locale's separator and no fraction when it is whole (`28`, `28,50`).
- A price of 0 is allowed (the domain allows it), an empty price field is not.
- «Зберегти» is disabled while the name is blank or the price does not parse.
- «Скасувати» or swiping the sheet down discards the changes without asking.
- A name taken by another apartment shows «Квартира з такою назвою вже є» under the name field after
  «Зберегти»; the sheet stays open. Any other failed save shows a generic error message.
- Saving closes the sheet; the list updates through the repository stream.

## Architecture

- **Domain** (`Models/Apartment/`): `Apartment` loses `isArchived` and `sortOrder`; `ApartmentDraft`
  checks uniqueness against every apartment; `ApartmentNameOrder` as above. `DayEntry` loses
  `sortOrder`; `ReportBuilder` sorts a day's cleaned entries by `ApartmentNameOrder`.
- **Persistence**: `ApartmentRecord` loses `sortOrder` and `isArchived`, `DayEntryRecord` loses
  `sortOrder` (its `position` stays: it keeps a day's entries in planning order). The schema has not
  reached TestFlight, so `SchemaV1` changes in place (the convention allows it until then); an existing
  simulator store may need the app deleted once.
- **Repository**: `apartments() -> AsyncStream<[Apartment]>` yields in name order; `add`, `update`,
  `delete(_ id:)` (throws `.notFound` for an unknown id). Both the fake and the SwiftData repository sort
  with `ApartmentNameOrder`, not a fetch sort descriptor.
- **Money input** (`Formatting/MoneyInput`): `parse(_ text:, locale:) -> Money?` and
  `string(_ money:, locale:) -> String` for the price field. Accepts both `,` and `.` as the separator
  whatever the locale.
- **View models** (`Features/Apartments/`), test-first against `FakeApartmentRepository`:
  - `ApartmentsViewModel`: `observe()`, `rows: [ApartmentRow]` (id, name, price text, badge flag),
    `count`, `isEmpty`, the sheet route (`ApartmentSheet?`: `.new`, `.edit(Apartment)`), the pending
    deletion and `confirmDeletion() async`, an error message for a failed delete.
  - `ApartmentFormViewModel`: name, price text, access code, report flag; `canSave`; `title`;
    `nameError`; `save() async -> Bool` (true closes the sheet). Built with the repository and the
    apartment being edited, if any.
- **Views**: `ApartmentsView` (a `List` for swipe actions, rows on `Card`, the hidden list background
  over `Background`, the footnote as a section footer), `ApartmentFormView` (a `Form` in a
  `NavigationStack`, `presentationDetents([.medium, .large])`), `ContentUnavailableView` for the empty
  state. Strings under `apartments.*` in both languages.

## Branches

The logic comes first, in two branches, then the UI (the plan sets the exact split and sizes):

1. Delete instead of archive, name order, report order — domain, persistence, repositories, tests,
   and the product spec and `architecture.md` updated.
2. `MoneyInput` and the two view models, test-first.
3. The screen, the sheet, the empty state and the strings.

## Consequences for later features

- **Today, «Як учора»** copies the previous day's entries. An apartment deleted since then must not be
  copied back: Feature 4 filters the copy by the current template. Recorded in `docs/plan.md`.
- **Day plan** shows the template in the name order.

## Non-goals

Restoring a deleted apartment; manual ordering; showing or searching archived history from this tab;
a Settings entry point (Feature 9).

## Left to the builder

- The exact accessibility label wording and the plural strings in English.
- Whether the name-taken check also runs live while typing (the minimum is on save).
- How the October report fixture builds its template now that there is no `sortOrder`.
- Where the count line sits (a list section header is the iOS 18-compatible choice;
  `navigationSubtitle` is iOS 26 only), and whether the delete confirmation is an alert or a
  confirmation dialog.
