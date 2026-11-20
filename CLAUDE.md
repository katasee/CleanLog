# CLAUDE.md

Guidance for Claude Code in this repository.

## Project

CleanLog is an iPhone work log for cleaners: keep a template of your apartments with prices, plan
which ones you clean today, tick them off during the day, see what you earned and how long you
worked, and send the monthly report to your boss over WhatsApp in the exact format they already
use. It started as an app for one cleaner (the developer's mother) and is built from day one to
ship on the App Store as a general tool. All data is local (SwiftData); there is no server and no
account.

- Product spec — screens, data model, report format, non-goals:
  `docs/superpowers/specs/2026-11-13-cleanlog-design.md`. Keep it in sync with any decision that
  changes scope.
- Visual design (Liquid Glass, iOS 26): the Claude Design canvas
  https://claude.ai/artifact/SjjoWCGv15bAQJmGVeRCbM — the reference for every screen.
- Status and the ordered next steps: `docs/plan.md`. Read it at the start of a session; update it
  when a step is done or the order changes, once per finished feature rather than every turn.

Stack: SwiftUI, SwiftData, Swift Testing, iOS 18.0+, iPhone only, portrait, Swift 6 language mode
with default `MainActor` isolation. No third-party dependencies without asking first.

## Commands

Build (must succeed before any change is called done):

```bash
xcodebuild -scheme CleanLog -destination 'generic/platform=iOS Simulator' build
```

Test (once `CleanLogTests` exists; must pass before any change is called done):

```bash
xcodebuild -scheme CleanLog -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Lint (the PostToolUse hook runs it per file; run it on the tree before handing work over):

```bash
xcrun swift-format lint --strict --recursive CleanLog CleanLogTests
```

When Xcode has the project open, add `-derivedDataPath <scratch folder>` to `xcodebuild`: sharing
Xcode's DerivedData makes both builds fail with "database is locked".

## Feature workflow

Every feature goes through the same pipeline without being asked:

1. `superpowers:brainstorming` — agree on the design, unless the spec already settles it.
2. `superpowers:writing-plans` — the plan goes to `docs/superpowers/plans/`.
3. `swiftui-pro` (and `swift-concurrency-pro` for anything async) — review the plan's code and fold
   the accepted fixes in before implementation starts.
4. Implementation, test-first for domain logic and view models (`superpowers:test-driven-development`).
   Claude writes the code; the user reads it.
5. Build, test and lint green, then commit, push and a short PR description (below).

**A complex feature is split into separate logic and UI tasks — and, when it is big enough,
separate plans and branches.** Logic comes first: domain types, calculations, repository work and
the view model, each test-driven, with no SwiftUI view in the diff. The UI task then builds the
screen on a view model that already works and is tested, and adds no logic of its own beyond
layout and bindings. A task that needs both is two tasks. "Complex" is anything with more than one
screen state, a calculation, or a write; a pure layout tweak stays one task.

A feature's plan file is a working artifact: delete it once the feature is merged. The product
spec and `docs/plan.md` stay.

## Git

**Claude creates branches, commits and pushes.** One feature per branch (`feature/<short-name>`),
small commits with an imperative English subject. **Never add a `Co-Authored-By` trailer or any
other attribution line** to commits or PRs. Never force-push and never rewrite pushed history.

At the end of every PR, give a PR description in English, ready to paste: a one-line title, what
the user gets, the key changes as bullets, how it was verified. No attribution line.

## Language

**All project documentation, code, comments and commit messages are in English**, whatever language
the session is in. Ukrainian appears only as data: UI strings quoted verbatim (so they can be
grepped against the String Catalog) and the report format.

## Conventions

Detailed rules, all loaded at launch:

- @.claude/conventions/architecture.md — layers, folders, domain/persistence split, view models, concurrency, testing
- @.claude/conventions/code-style.md — formatting, Swift style, formatters, localization, typography, colour, Liquid Glass

Hooks in `.claude/settings.json` enforce what a machine can check: `swift-guard.sh` blocks
greppable convention breaks before a Swift file is written, and `swift-format-lint.sh` lints it
after. A hook denial is a rule, not an obstacle — fix the code, don't work around the hook. When a
rule turns out wrong, change the convention file and the hook together, in the same change.
