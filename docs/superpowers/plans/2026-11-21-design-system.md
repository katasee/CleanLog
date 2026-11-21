# Design system Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The colour tokens, the glass and card surfaces, the String Catalog and the three-tab shell
every later screen is built in.

**Architecture:** Colorsets in `Assets.xcassets` and keys in `Localizable.xcstrings`, both used
through Xcode's generated symbols; two view modifiers in `UICommons/`; a `RootView` in `App/` with
the system `TabView` holding one placeholder view per feature folder.

**Tech Stack:** SwiftUI (iOS 18.0+, Liquid Glass on 26), asset catalog, String Catalog.

**Spec:** `docs/superpowers/specs/2026-11-21-design-system-design.md`

## Global Constraints

- iOS 18.0+, iPhone, portrait; Swift 6, default `MainActor` isolation.
- Colour values exactly as the `code-style.md` table; one role per token; no hex in Swift.
- The only `if #available(iOS 26, *)` for glass is inside `.glassSurface(_:)`.
- No user-facing string literal in a view; keys `feature.kind.name`, all three languages.
- No comments in Swift; layout numbers in a `private enum Layout`.
- `#Preview`s that use debug-only code sit inside `#if DEBUG`.

## Review Focus

- **Dark appearance**: every colorset has a dark variant; a token with only "Any" would show the
  light value at night. Check: each `Contents.json` holds two `colors` entries, the second with
  `"appearances": [{"appearance": "luminosity", "value": "dark"}]`.
- **`Color.background` vs `.background`**: in `.background(…)` or `foregroundStyle(…)` the bare
  `.background` resolves to the system `BackgroundStyle`, not our token. Always write
  `Color.background`.
- **Glass on iOS 18**: the material branch only runs on 18. Run the `UICommons` preview (or the app)
  on an iOS 18 simulator if one is installed; otherwise state that it was only compiled.
- **Release build**: `#Preview` compiles in Release; `xcodebuild -configuration Release` before the
  PR of each branch.
- **Language fallback**: with `developmentRegion = uk`, a device whose languages are none of
  uk/pl/en shows Ukrainian. Accepted for now (the conventions make Ukrainian the development copy);
  revisit before the App Store release.

## Plan review

`swiftui-pro` (2026-11-21): no blocking findings. Task 5 may use a `Tab` initializer that takes the
title as a `LocalizedStringResource` directly if the SDK has one, instead of the `Label` closure.
The skill's "one type per file" yields to `code-style.md`: a private supporting `ViewModifier`
stays beside its `View` extension. No `async` code, so no `swift-concurrency-pro` pass.

## Branches

| CL | Branch | Base | Tasks |
|---|---|---|---|
| 8 | `feature/CL-8-design-system` | `main` | 1–3 |
| 9 | `feature/CL-9-tab-shell` | CL-8 (or `main` once merged) | 4–5 |

Size excludes the deleted foundation docs (a pure deletion, ~440 lines): CL-8 is about 320 lines
(mostly colorset JSON), CL-9 about 250 and the natural end of the feature.

---

### Task 1: Close Feature 1

**Files:**
- Delete: `docs/superpowers/plans/2026-11-20-foundation.md`,
  `docs/superpowers/specs/2026-11-20-foundation-design.md`
- Modify: `docs/plan.md`

- [ ] **Step 1:** `git rm` both files.
- [ ] **Step 2:** In `docs/plan.md`: Feature 1 heading says done and drops its Plan/Spec line; the
  CL-7 row says merged (PR #7); the "After branch 7 merges" and "NEXT, once PR #7" notes go; a
  Feature 2 section with this plan's branch table, CL-8 marked in progress; roadmap item 1 done,
  item 2 in progress; next free number CL-10.
- [ ] **Step 3:** Commit `Close the foundation feature`.

### Task 2: Colour tokens

**Files:**
- Modify: `CleanLog/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `CleanLog/Resources/Assets.xcassets/{Ink,InkSecondary,AccentSoft,Background,Card,Separator,Warning}.colorset/Contents.json`

**Interfaces:**
- Produces: `Color.ink`, `.inkSecondary`, `.accentSoft`, `.background`, `.card`, `.separator`,
  `.warning` (generated), and `Color.accentColor`.

- [ ] **Step 1:** Each colorset: sRGB, `"idiom": "universal"`, one entry without appearances (light)
  and one with the dark luminosity appearance; components as `0xNN` hex strings, alpha `1.000`
  except `Separator`: light `#0B1215` alpha `0.080`, dark `#FFFFFF` alpha `0.100`. Values:

  | Token | Light | Dark |
  |---|---|---|
  | Ink | `#0B1215` | `#F2F5F6` |
  | InkSecondary | `#4F5D65` | `#A3B0B7` |
  | AccentColor | `#0B7A75` | `#3FC2B7` |
  | AccentSoft | `#DDEFEE` | `#173634` |
  | Background | `#EEF2F3` | `#0B0F11` |
  | Card | `#FFFFFF` | `#1A2124` |
  | Warning | `#9A5B00` | `#FFB340` |

- [ ] **Step 2:** Build. Expected: `BUILD SUCCEEDED`, and
  `grep -l '"dark"' CleanLog/Resources/Assets.xcassets/*.colorset/Contents.json | wc -l` prints `8`.
- [ ] **Step 3:** Commit `Add the colour tokens`.

### Task 3: Glass and card surfaces

**Files:**
- Create: `CleanLog/UICommons/GlassSurface.swift`, `CleanLog/UICommons/CardSurface.swift`

**Interfaces:**
- Produces: `extension View { func glassSurface(_ shape: some Shape) -> some View }` and
  `extension View { func cardSurface() -> some View }`.

- [ ] **Step 1:** `GlassSurface.swift`: a private `struct GlassSurface<SurfaceShape: Shape>: ViewModifier`
  first, then the `View` extension. iOS 26: `glassEffect(.regular.interactive(), in: shape)` — our
  glass is always on a touched control, so it is always interactive. iOS 18:
  `background(.regularMaterial, in: shape)`.
- [ ] **Step 2:** `CardSurface.swift`: a private `ViewModifier` applying `padding(Layout.padding)` then
  `background(Color.card, in: .rect(cornerRadius: Layout.cornerRadius))`; `Layout.padding = 16`,
  `Layout.cornerRadius = 24` (the canvas cards).
- [ ] **Step 3:** One `#Preview` per file, each on `Color.background`: a card holding two lines of text in `Color.ink` / `.inkSecondary`;
  a 44×44 circle button with an SF Symbol under `.glassSurface(.circle)` and `.buttonStyle(.plain)`.
  Preview text is not user-facing, but the guard and the localization rule still apply: use
  `Text(verbatim:)`.
- [ ] **Step 4:** Build, lint. Commit `Add the glass and card surfaces`.

### Task 4: String Catalog and languages

**Files:**
- Modify: `CleanLog.xcodeproj/project.pbxproj` (`developmentRegion = uk;`, `knownRegions` = `uk, pl,
  en, Base`)
- Create: `CleanLog/Resources/Localizable.xcstrings` (`sourceLanguage` `uk`)

**Interfaces:**
- Produces: generated `LocalizedStringResource` symbols `.tabTodayTitle`, `.tabStatsTitle`,
  `.tabApartmentsTitle`.

- [ ] **Step 1:** Keys, `extractionState: manual`, each with `uk`, `pl`, `en` `stringUnit`s
  (`state: translated`):

  | Key | uk | pl | en |
  |---|---|---|---|
  | `tab.today.title` | Сьогодні | Dzisiaj | Today |
  | `tab.stats.title` | Статистика | Statystyki | Statistics |
  | `tab.apartments.title` | Квартири | Mieszkania | Apartments |

- [ ] **Step 2:** Build. Expected: `BUILD SUCCEEDED`; the generated symbols exist (a throwaway
  `Text(.tabTodayTitle)` compiles — the next task uses it for real).
- [ ] **Step 3:** Commit `Add the string catalog in three languages`.

### Task 5: Tab shell

**Files:**
- Create: `CleanLog/App/AppTab.swift`, `CleanLog/App/RootView.swift`,
  `CleanLog/Features/Today/TodayView.swift`, `CleanLog/Features/Stats/StatsView.swift`,
  `CleanLog/Features/Apartments/ApartmentsView.swift`
- Modify: `CleanLog/App/CleanLogApp.swift` (`RootView()` instead of `ContentView()`)
- Delete: `CleanLog/App/ContentView.swift`

**Interfaces:**
- Consumes: Task 2 colours, Task 4 symbols.
- Produces: `enum AppTab: Hashable { case today, stats, apartments }`; `struct RootView: View`.

- [ ] **Step 1:** `RootView`: `@State private var selectedTab: AppTab = .today`;
  `TabView(selection:)` with three `Tab(value:content:label:)` in the order Today, Statistics,
  Apartments; labels `Label { Text(.tabTodayTitle) } icon: { Image(systemName:) }` with
  `checkmark.circle`, `chart.bar`, `building.2`.
- [ ] **Step 2:** Each placeholder: `NavigationStack` around `Color.background.ignoresSafeArea()`
  with `.navigationTitle(Text(.tab…Title))`. No dependencies, no view model yet.
- [ ] **Step 3:** `#Preview { RootView() }` (reads no debug-only code, so no `#if DEBUG`).
- [ ] **Step 4:** Build Debug and Release, full test run, lint. Launch on the iPhone 16 simulator
  in light and dark: three tabs, Today selected, titles in the device language.
- [ ] **Step 5:** Commit `Replace the template view with the tab shell`.
