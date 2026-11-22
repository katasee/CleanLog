# Screen background — design

## Intent

The user reviewed the Apartments screen and wants the design canvas's background on every screen in
place of the flat `Background` fill. On the canvas that background is not a gradient: it is a pale
teal fill with two large blurred circles, placed a little differently on each screen. The user
chose to keep the per-screen placement, as drawn.

Goals: every tab screen (Today, Statistics, Apartments) and every later screen shows the fill and
its two circles, in light and dark. Non-goals: the canvas's translucent cards (cards stay flat on
`Card`, as `code-style.md` says), any animation of the circles. Anti-goal: a background that makes
text or cards harder to read, or that moves while the content scrolls.

## Approaches

1. **(Chosen) One `.screenBackground(_:)` modifier in `UICommons/`, the placement passed in by each
   screen.** It draws the `Background` fill and two blurred circles. A screen passes its own
   placement (a value type: two circles, each with a colour role, diameter, position and opacity)
   from its `Layout` enum, so `UICommons` knows no feature. Closest to the canvas, colours from
   colorsets, sizes relative to the screen so every iPhone looks alike.
2. `MeshGradient` (iOS 18+): cheap and smooth, but gives no round spots and a per-screen 3×3 grid
   of points and colours is hard to read or match to the canvas.
3. Pre-rendered images per screen and appearance: exact, but six or more assets that do not adapt
   to the screen size and must be redrawn for every change.

## Placements (from the canvas, 390 × 844 pt frame, blur 70)

| Screen | Circle 1 | Circle 2 |
|---|---|---|
| Today | glow, Ø360, right −120, top −100, 55 % | mist, Ø320, left −150, top 300, 60 % |
| Statistics | glow, Ø340, left −110, top −80, 55 % | mist, Ø300, right −150, top 420, 60 % |
| Apartments | mist, Ø340, right −130, top −60, 60 % | glow, Ø300, left −150, top 460, 40 % |

Later screens (calendar, report, day plan) are sheets or popups over these and get no placement of
their own; a later full screen picks one when it is built.

## Colours

- `Background` light changes from `#EEF2F3` to the canvas's `#E6F7F8`; dark stays `#0B0F11`.
- Two new colorsets, one role each: `BackdropGlow` (the stronger circle, light `#8CE2EA`) and
  `BackdropMist` (the softer one, light `#C3F0F3`). The canvas has no dark mode; proposal: glow
  `#0F4C4F`, mist `#12302F` — dark enough that `Ink` text keeps its contrast. Confirm on a device
  with the rest of the dark values.
- `code-style.md`'s colour table gains both tokens, and the surfaces section says every screen sets
  its background through `.screenBackground(_:)`.

## Builder's calls (correctable)

- Horizontal position and diameter are fractions of the screen width, vertical position a fraction
  of its height, all derived from the 390 × 844 frame above; the background ignores the safe area
  and stays fixed while the content scrolls over it.
- The blur radius is a `Layout` constant in the modifier (canvas `blur(70px)`); tuned by eye on the
  simulator so it looks like the canvas.
- The circles are decoration: hidden from accessibility and not hit-testable.
- The placement values live next to each screen (`TodayView`, `StatsView`, `ApartmentsView`).
- The Apartments form's popup keeps its material backdrop; it now blurs the circles too.
- On this branch, the finished apartments plan file is deleted (Feature 3 is merged).
