# Code style

## Formatting

- **`swift-format` with the repo's `.swift-format` is the formatter of record** (4 spaces, 120
  columns, no force unwrap / force try / IUO). The PostToolUse hook lints every Swift file Claude
  writes; fix what it reports before moving on. Run it by hand with
  `xcrun swift-format lint --strict --recursive CleanLog`.
- **A call or declaration with 3+ arguments puts one argument per line.** A trailing closure does
  not count: `VStack(alignment: .leading, spacing: 8) { … }` stays on one line. Fixture literals in
  `#if DEBUG` preview data may stay packed — they read as a table.
- One type per file, named after the file, except a supporting type that only serves its neighbour
  (see `architecture.md`).

## Swift

- **`private` by default**, `internal` when another file needs it, never `public` (one module).
  Classes are `final`.
- `let` over `var`, value types over classes, `guard` for early exits.
- No `!` and no `try!`. A truly impossible case is `preconditionFailure("why")`, not a crash in
  disguise. `try?` only where the failure genuinely does not matter, never to silence a write.
- Errors are typed enums per feature or repository (`WorkDayRepositoryError`), surfaced to the
  user as a localized message by the view model — never swallowed, never `print`ed.
- No `print`. Diagnostics go through `Logger(subsystem:category:)` from `os`, one `Logger` per type.
- Names say what, not how: `markCleaned(_:)`, not `toggle()`; `isPlanned`, not `flag`. Booleans
  read as assertions (`isRunning`, `hasEntries`, `canSave`).
- **No comments in code** — no `//`, no `///` doc comments, no `// MARK:`, no commented-out code,
  in the app and in tests. Names, types and small functions carry the meaning; a reason worth
  keeping goes into the commit message, the plan or `.claude/conventions/`. The guard hook blocks
  comment lines in Swift files.
- Modern API only: `foregroundStyle` (not `foregroundColor`), `clipShape(.rect(cornerRadius:))`
  (not `cornerRadius`), `NavigationStack`, `onChange(of:) { old, new in }`, `Tab(…)`,
  `sensoryFeedback` / `UIFeedbackGenerator`, `Text(_:format:)` over string interpolation of numbers.

## Formatting values

- **Every formatter lives in `Formatting/`.** No inline `DateFormatter`, `NumberFormatter` or
  `.formatted(…)` with a hand-picked style in a view or view model.
- **Display** formatters follow `Locale.current` and use templates
  (`setLocalizedDateFormatFromTemplate("dMMMM")`, `Date.FormatStyle` fields), never a fixed
  pattern: a fixed `"d MMMM"` is right in Ukrainian and wrong in English.
- **The report** is the user's boss's fixed format (`13.11-(100,101,102)=3+106`). It pins
  `en_US_POSIX`, is built only by `ReportBuilder`, and is tested against the real October report.
- Money goes through `MoneyFormat` (always zł, no fraction digits when the amount is whole).
  Numbers that change in place (timer, sums) get `.monospacedDigit()`.

## Localization

- **No user-facing string literal in a view.** Every string is in `Resources/Localizable.xcstrings`
  under a `feature.kind.name` key (`today.empty.title`, `report.action.send`) and is used through
  the symbol the catalog generates (`STRING_CATALOG_GENERATE_SYMBOLS = YES`), so a missing key is a
  compile error. Add the key, with both languages, in the same change that uses it.
- Languages: Ukrainian (development copy) and English; no Polish. Plurals ("1 квартира / 3 квартири /
  5 квартир") are catalog plural variations, never `if count == 1`.
- Ukrainian copy speaks to the user informally («Додай квартири»):
  the app is a personal tool, not an institution.
- Not localized: apartment names (user data) and the report text (the boss's format).

## Typography

- **System font, Dynamic Type text styles only**: `.font(.title2.weight(.semibold))`,
  `.font(.body)`. Never `.font(.system(size:))` — the main user reads with large text, and fixed
  sizes don't scale. The large numbers (timer, monthly total) use `.largeTitle` with
  `.fontDesign(.rounded)` and `.monospacedDigit()`.
- Weight comes from the text style or `.weight(_:)` on the font, not `.bold()` sprinkled on views.

## Colour

Every colour is a colorset in `Assets.xcassets` with light and dark appearances, used through the
generated symbol (`Color.ink`). No hex, no `Color(red:green:blue:)`, no `colorScheme` branches in
views. **Each token has one role:**

| Token | Role | Light / dark |
|---|---|---|
| `Ink` | primary text and glyphs | `#0B1215` / `#F2F5F6` |
| `InkSecondary` | secondary text, captions | `#4F5D65` / `#A3B0B7` |
| `AccentColor` | primary actions, checkmarks, the selected state | `#0B7A75` / `#3FC2B7` |
| `AccentSoft` | tinted fills under accent text (badges, progress track) | `#DDEFEE` / `#173634` |
| `Background` | the screen fill under the backdrop circles | `#E6F7F8` / `#0B0F11` |
| `BackdropGlow` | the stronger backdrop circle | `#8CE2EA` / `#0F4C4F` |
| `BackdropMist` | the softer backdrop circle | `#C3F0F3` / `#12302F` |
| `Card` | content cards and list groups | `#FFFFFF` / `#1A2124` |
| `OnAccent` | text and glyphs on an `AccentColor` fill (a selected tile, a checkmark) | `#FFFFFF` / `#1A2124` |
| `Hairline` | hairlines between rows | ink 8% / white 10% |
| `Warning` | a paused timer, a day that needs attention | `#9A5B00` / `#FFB340` |
| `Destructive` | a destructive action that asks for confirmation first (a swipe to delete) | `#FF3B30` / `#FF453A` |

Dark values are a first proposal; confirm them on a device before the first TestFlight. Never name a
colorset after an existing `Color` or `UIColor` member (`Primary` collides with `Color.primary`,
`Separator` with `UIColor.separator`): Xcode then skips the generated symbol with a warning.

## Surfaces and Liquid Glass

- **Glass is the control layer, content is flat.** Tab bar, toolbar buttons, the floating add
  button, the timer controls and sheets are glass; cards, rows and text sit on `Card`. Text on glass
  reads worse, and glass over glass cannot refract.
- **The tab bar, toolbars and sheets get glass from the system** on iOS 26 — never draw them.
- **Our own glass goes through one modifier, `.glassSurface(_:)` in `UICommons/`**, which holds
  the only `if #available(iOS 26, *)` for it: `.glassEffect(…)` on 26, `.background(.regularMaterial,
  in: shape)` on 18. A feature never calls `.glassEffect` directly (the guard hook blocks it).
- Glass goes on the view that is touched (`.interactive()` reacts only there), and a glass button
  uses `.buttonStyle(.plain)` so the glass is the press feedback, not a second scale effect.
- **Every screen sets its background with `.screenBackground(_:)` from `UICommons/`**, passing its
  own circles from its `Layout`; a screen never paints `Color.background` itself (a `#Preview` may).
- Cards use `.cardSurface()` from `UICommons/` — fill, corner radius and padding in one place.
- Icons are SF Symbols (`Image(systemName:)`), sized by the text style they sit next to.
- Touch targets are at least 44×44 pt.
