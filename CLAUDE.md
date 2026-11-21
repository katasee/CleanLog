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

1. `superpowers:brainstorming` — always, for every feature, even when the spec covers most of it:
   confirm what the spec settles and agree on what it leaves open.
2. `superpowers:writing-plans` — the plan goes to `docs/superpowers/plans/`.
3. **Plan review** — before any code is written, review the plan's code with the skills that fit it
   and fold the accepted fixes into the plan:
   - `swiftui-pro` for anything with SwiftUI views or view models;
   - `swift-concurrency-pro` for anything with `async`, streams, tasks, actors or the timer;
   - both when the plan touches both.
4. Implementation, test-first for domain logic and view models (`superpowers:test-driven-development`).
   Claude writes the code; the user reads it.
5. **Code review** — after implementation, on the actual diff:
   - the same skill(s) as step 3 again, because the code drifts from the plan;
   - a **SOLID and clean-code pass**: single responsibility per type, dependencies on protocols
     (not concrete repositories), no type that has to change for an unrelated reason, small
     functions with one level of abstraction, intention-revealing names, no duplication, no dead
     code, and every rule in `.claude/conventions/`.
   Fix what the reviews find, then build, test and lint again.
6. Build, test and lint green, then commit, push the branch and open its PR (below). What each
   review found and what was fixed goes into `docs/plan.md`, not the PR description.

**A complex feature is split into separate logic and UI tasks — and, when it is big enough,
separate plans and branches.** Logic comes first: domain types, calculations, repository work and
the view model, each test-driven, with no SwiftUI view in the diff. The UI task then builds the
screen on a view model that already works and is tested, and adds no logic of its own beyond
layout and bindings. A task that needs both is two tasks. "Complex" is anything with more than one
screen state, a calculation, or a write; a pure layout tweak stays one task.

## Branches and sessions

**Every branch is 300–500 changed lines, tests included** (`git diff --shortstat <base>...HEAD`).
A plan is split into branches before implementation starts, and the split is written into
`docs/plan.md`. A branch smaller than 300 lines is fine only when it is the natural end of a
feature; a branch growing past 500 stops and is split.

**Every branch is done in a fresh session (`/clear`, zero context).** A session works on exactly one
branch: read `docs/plan.md` first, find the branch marked next, read its plan section and spec, do
it, and stop. Everything the next session needs goes into `docs/plan.md` and the plan file — never
rely on conversation memory. Start Claude Code in the repo folder so the project hooks load.

**Every branch gets a thorough code review before it is handed over** — the review step of the
feature workflow, on that branch's diff only: the matching skills (`swift-concurrency-pro`,
`swiftui-pro`) and the SOLID / clean-code pass. Fix what it finds, re-run build, tests and lint,
and record the result in `docs/plan.md`.

**Branches are stacked** while the one below is not merged yet: each starts from the previous
branch of the same feature, and its PR targets that branch (or `main` once it is merged).

A feature's plan file is a working artifact: delete it once the feature is merged. The product
spec and `docs/plan.md` stay.

## Git

**Claude creates branches and commits, pushes `feature/*` branches and opens their PRs** with
`gh pr create` (base = the branch below in the stack, or `main`). Branch names
`feature/CL-<n>-<short-name>`, where `CL-<n>` is a project-wide sequence number (the next free one
is in `docs/plan.md`) and the short name says what the branch adds (`feature/CL-6-swiftdata`).
Small commits with an imperative English subject.
**Never add a `Co-Authored-By` trailer or any other attribution line** to commits or PRs. Never
push `main`, never force anything, never delete a remote branch, never rewrite pushed history;
`.claude/settings.json` allows only `git push [-u] origin feature/*`.

The PR description is in English: a one-line title, what the user gets, the key changes as
bullets. No review findings, no "how it was verified" section, no attribution line.

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
