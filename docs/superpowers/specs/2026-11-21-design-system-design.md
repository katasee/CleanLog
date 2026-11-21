# Feature 2 — Design system

Started 2026-11-21. Approved in the brainstorming session. Product spec:
`2026-11-13-cleanlog-design.md`; visual reference: the Claude Design canvas
(https://claude.ai/artifact/SjjoWCGv15bAQJmGVeRCbM).

## Why

Every later screen needs the same colours, the same card and glass surfaces, localized strings and
the tab shell to live in. Building them once, before the first screen, keeps the features from
inventing their own copies.

## Goals

- The eight colour tokens from `code-style.md` as colorsets with light and dark appearances.
- `.glassSurface(_:)` and `.cardSurface()` in `UICommons/`.
- `Localizable.xcstrings` with Ukrainian (development language), Polish and English.
- A `RootView` with the system `TabView` and three tabs — Today, Statistics, Apartments — each a
  placeholder screen in its own feature folder, replacing the template `ContentView`.
- Closing Feature 1: the foundation plan and design files deleted, Feature 1 marked done in
  `docs/plan.md`.

## Non-goals

- **Themes.** The canvas once held eleven colour variants of Today; they were dropped. One teal
  palette, exactly the `code-style.md` table.
- **The floating add button.** It opens the Day plan sheet, which arrives in Feature 5; a button
  with nothing to open would be dead code. Its placement beside the tab bar (and the iOS 18
  fallback) is decided there.
- The blurred colour blobs behind the canvas screens: the screen background is the flat
  `Background` token.
- Any real screen content, view model or settings.

## Constraints

- The conventions in `.claude/conventions/` (Liquid Glass, colour, typography, localization).
- iOS 18.0+: glass on iOS 26, `.regularMaterial` on 18, from one modifier with the only
  `#available` for glass.
- `#Preview`s that use debug-only code sit inside `#if DEBUG` (CL-7 finding); the pre-PR check
  includes a Release build.

## Approaches

| | Approach | Trade-off |
|---|---|---|
| **A (chosen)** | System pieces: asset-catalog colorsets, String Catalog with generated symbols, system `TabView` with the `Tab` API | least code; glass on 26 and the standard bar on 18 come from the system |
| B | A theme layer (runtime palettes, a theme setting) | only needed for the dropped colour variants |
| C | A custom tab bar matching the canvas pixel for pixel | forbidden by `architecture.md`; loses system glass and accessibility |

Only A fits the conventions and the canvas as it stands.

## Decided

- **Colorsets**: `Ink`, `InkSecondary`, `AccentColor` (exists, gets its values), `AccentSoft`,
  `Background`, `Card`, `Separator`, `Warning`, with the light/dark values from the
  `code-style.md` table, used through the generated symbols (`Color.ink`, `.accentSoft`, …).
- **`developmentRegion`** becomes `uk`; `knownRegions` gains `uk` and `pl`.
- **String keys** follow `feature.kind.name`; this feature adds only the three tab titles
  (`tab.today.title`, `tab.stats.title`, `tab.apartments.title`) in all three languages.
- **Tabs**: Today, Statistics, Apartments, in that order, Today selected at launch. SF Symbols
  matching the canvas glyphs: a checkmark in a circle, a bar chart, a building.
- **Placeholders**: `Features/Today/TodayView`, `Features/Stats/StatsView`,
  `Features/Apartments/ApartmentsView`, each a `NavigationStack` with the tab's title as its
  navigation title on the `Background` colour.
- **`RootView`** lives in `App/`; `CleanLogApp` shows it with the dependencies in the environment.

## Left to the builder

- The tab selection type (an enum in `App/`) and whether it is stored.
- Exact SF Symbol names, and `.cardSurface()`'s radius and padding (from the canvas: 24 pt
  corners, 16 pt padding).
- `.glassSurface(_:)`'s parameter: the shape the glass fills.
- How the modifiers are covered: they are layout, so a `#Preview` in `UICommons/` rather than
  unit tests.
