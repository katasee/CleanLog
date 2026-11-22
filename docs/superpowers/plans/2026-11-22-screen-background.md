# Screen background Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every tab screen shows the canvas background — the `Background` fill with two large blurred
circles placed per screen — in light and dark.

**Architecture:** A `BackdropCircle` value in `UICommons/` holds one circle in the canvas's 390 × 844
frame and scales it to the real screen (pure, tested). A `.screenBackground(_:)` modifier beside it
draws the fill and the circles behind the content, ignoring the safe area. Each screen passes its
circles from its own `Layout` enum.

**Tech Stack:** SwiftUI, Swift Testing, asset-catalog colorsets.

**Spec:** `docs/superpowers/specs/2026-11-22-screen-background-design.md`

Branch: `feature/CL-14-gradient-background` (base `main`), one branch, all three tasks; small,
the natural end of the background work.

## Global Constraints

- iOS 18.0+, iPhone, portrait; Swift 6, default `MainActor` isolation; no third-party code.
- Colours only through colorsets and their generated symbols; no hex in Swift, no `colorScheme`
  branches.
- `Background` light `#E6F7F8` (was `#EEF2F3`), dark `#0B0F11` unchanged.
- `BackdropGlow` light `#8CE2EA`, dark `#0F4C4F`; `BackdropMist` light `#C3F0F3`, dark `#12302F`.
- Reference frame 390 × 844 pt; canvas blur `70px`.
- No comments in Swift; layout numbers in `private enum Layout`; `#Preview` with fixture data inside
  `#if DEBUG` only when it uses fakes (these previews use none).
- No user-facing strings are added.

## Review Focus

1. **The keyboard comes up** (the Apartments form popup): the background must not shrink or the
   circles jump — the background ignores every safe-area region, the keyboard's included.
2. **The list scrolls**: the circles stay fixed behind the rows, they do not scroll with them.
3. **Dark mode**: `Ink` / `InkSecondary` text and the `Card` rows stay readable over the dark
   circles; the circles must not read as stains.
4. **VoiceOver / touches**: the circles are not elements and never take a tap.
5. **Other iPhone sizes** (SE 375 × 667, Pro Max 440 × 956): the circles scale and keep their place
   — covered by `BackdropCircleTests`.

---

### Task 1: Colours and conventions

**Files:**
- Modify: `CleanLog/Resources/Assets.xcassets/Background.colorset/Contents.json` (light → `0xE6 0xF7 0xF8`)
- Create: `CleanLog/Resources/Assets.xcassets/BackdropGlow.colorset/Contents.json`
- Create: `CleanLog/Resources/Assets.xcassets/BackdropMist.colorset/Contents.json`
- Modify: `.claude/conventions/code-style.md` (colour table, surfaces section)
- Delete: `docs/superpowers/plans/2026-11-21-apartments.md` (Feature 3 is merged)

**Interfaces:**
- Produces: `Color.backdropGlow`, `Color.backdropMist` (generated symbols).

- [ ] **Step 1:** Change `Background`'s light components and add the two colorsets, same JSON shape
  as `Background.colorset` (universal + dark luminosity), values from Global Constraints.
- [ ] **Step 2:** In `code-style.md`: `Background` row → `#E6F7F8` / `#0B0F11`, role "the screen fill
  under the backdrop circles"; add rows `BackdropGlow` — "the stronger backdrop circle" and
  `BackdropMist` — "the softer backdrop circle" with their values. In "Surfaces and Liquid Glass"
  add: "**Every screen sets its background with `.screenBackground(_:)` from `UICommons/`**, passing
  its own circles from its `Layout`; never `Color.background` directly."
- [ ] **Step 3:** Build. Expected: `BUILD SUCCEEDED`, no "skipping generated symbol" warning for the
  new colorsets.
- [ ] **Step 4:** Commit `Add the backdrop colours and drop the finished apartments plan`.

### Task 2: `BackdropCircle` and `.screenBackground(_:)`

**Files:**
- Create: `CleanLog/UICommons/BackdropCircle.swift`
- Create: `CleanLog/UICommons/ScreenBackground.swift`
- Test: `CleanLogTests/UICommons/BackdropCircleTests.swift`

**Interfaces:**
- Consumes: `Color.background`, `Color.backdropGlow`, `Color.backdropMist`.
- Produces:
  ```swift
  struct BackdropCircle: Hashable {
      enum Tone: Hashable { case glow, mist }
      static let referenceSize: CGSize          // 390 × 844
      let tone: Tone
      let origin: CGPoint                       // top-left, in the reference frame
      let diameter: CGFloat                     // in the reference frame
      let opacity: Double
      func frame(in size: CGSize) -> CGRect
  }
  extension View { func screenBackground(_ circles: [BackdropCircle]) -> some View }
  ```

- [ ] **Step 1: Write the failing tests** (`@Suite struct BackdropCircleTests`)

  ```swift
  private let circle = BackdropCircle(tone: .glow, origin: CGPoint(x: 150, y: -100), diameter: 360, opacity: 0.55)

  @Test func keepsTheCanvasFrameAtTheReferenceSize() {
      #expect(circle.frame(in: CGSize(width: 390, height: 844)) == CGRect(x: 150, y: -100, width: 360, height: 360))
  }

  @Test func scalesWithTheScreen() {
      #expect(circle.frame(in: CGSize(width: 780, height: 1688)) == CGRect(x: 300, y: -200, width: 720, height: 720))
  }

  @Test func sizesByWidthAndPlacesVerticallyByHeight() {
      #expect(circle.frame(in: CGSize(width: 390, height: 422)) == CGRect(x: 150, y: -50, width: 360, height: 360))
  }
  ```
  (The packed initializer above is for reading; in the file put one argument per line.)
- [ ] **Step 2:** Run `-only-testing:CleanLogTests/BackdropCircleTests`. Expected: fails to compile,
  `BackdropCircle` not found.
- [ ] **Step 3:** Implement `BackdropCircle`: x and diameter scale by `size.width / 390`, y by
  `size.height / 844`; the circle stays round.
- [ ] **Step 4:** Run the suite. Expected: 3 tests pass.
- [ ] **Step 5:** Implement `ScreenBackground` (private `ViewModifier`) and the `screenBackground(_:)`
  extension: `content.background { … }` holding a `GeometryReader` over a top-leading `ZStack` of
  `Color.background` and, per circle, `Circle().fill(tone colour).opacity(_:)` sized and offset by
  `frame(in: proxy.size)` and blurred by `Layout.blurRadius` (start at `70`, tune by eye against the
  canvas). The `GeometryReader` itself gets `.ignoresSafeArea()` (all regions, so the keyboard
  does not shrink it), then `.accessibilityHidden(true)`,
  `.allowsHitTesting(false)`. The tone → colour mapping is a private computed property in this file.
  A `#Preview` shows a card over the Today circles.
- [ ] **Step 6:** Build and lint the two files. Expected: green.
- [ ] **Step 7:** Commit `Draw the screen background with blurred circles`.

### Task 3: Each screen gets its circles

**Files:**
- Modify: `CleanLog/Features/Today/TodayView.swift`
- Modify: `CleanLog/Features/Stats/StatsView.swift`
- Modify: `CleanLog/Features/Apartments/ApartmentsView.swift`

**Interfaces:**
- Consumes: `BackdropCircle`, `screenBackground(_:)` from Task 2.

- [ ] **Step 1:** Each view gets a `private enum Layout { static let backdrop: [BackdropCircle] }`
  (in `ApartmentsView` beside its existing views), origins converted from the spec's table
  (right offset `r` → `x = 390 + r − diameter`):

  | Screen | circles (tone, origin, diameter, opacity) |
  |---|---|
  | Today | glow (150, −100) 360 0.55 · mist (−150, 300) 320 0.6 |
  | Stats | glow (−110, −80) 340 0.55 · mist (240, 420) 300 0.6 |
  | Apartments | mist (180, −60) 340 0.6 · glow (−150, 460) 300 0.4 |
- [ ] **Step 2:** Today and Stats: `Color.background.ignoresSafeArea()` → `Color.clear` with
  `.screenBackground(Layout.backdrop)`; Apartments: `.background(Color.background)` →
  `.screenBackground(Layout.backdrop)`. `grep -rn "Color.background" CleanLog/Features` returns
  nothing.
- [ ] **Step 3:** Build Debug and Release; run the full tests and lint.
- [ ] **Step 4:** Launch on the iPhone 16 simulator: the three tabs in light and dark, the Apartments
  list scrolled, the form popup open. Compare with the canvas; tune `Layout.blurRadius` if needed
  (commit with Task 3).
- [ ] **Step 5:** Commit `Give every tab screen its backdrop circles`.

## Plan review (before code)

`swiftui-pro` (2026-11-22), no blocking findings. Folded in:

- `.ignoresSafeArea()` goes on the `GeometryReader` itself, inside the `background { }` closure —
  applied outside it, `proxy.size` excludes the status bar and home indicator, so every circle is
  placed against a smaller frame than the screen and the top ones sit too low.
- `ForEach(circles, id: \.self)`: two identical circles on one screen would share an identity, but
  they would also draw the same pixels twice — not a case worth an index id.

Checked and kept: the tone → colour mapping is a `Color`-returning property, not a `some View`
helper; the circle inputs are a static `let` array, so the background's body does not re-run when
the screen's state changes; the Apartments `List` already hides its scroll background, so the
circles show through between the rows.
