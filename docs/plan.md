# CleanLog — plan and status

The living checklist. A fresh session reads this first, takes the branch marked **NEXT**, works on
that branch only, updates this file, and stops. Rules: `CLAUDE.md` (Branches and sessions).

## How a session runs

1. `git switch <branch>` (create it from its base when the table says so).
2. Read the branch's tasks in the plan file and the spec it points to.
3. **Implement** (if the branch is not built yet): the plan's steps, test-first, one commit per task.
4. **Review** the branch diff (`git diff <base>...HEAD`): `swift-concurrency-pro` and/or `swiftui-pro`
   as the table says, then the SOLID / clean-code pass and every rule in `.claude/conventions/`.
   Fix findings in new commits on the same branch.
5. Build, test, `xcrun swift-format lint --strict --recursive CleanLog CleanLogTests` — all green.
6. If the review changed code, merge this branch into every later branch of the stack that already
   exists (`git switch <later> && git merge <this>`), re-run its tests. Never rebase.
7. Update the table below (status, review result), push the branch, open its PR with `gh pr create`
   (base = the branch's base; description as in `CLAUDE.md` → Git), stop.

## Feature 1 — Foundation

Plan: `docs/superpowers/plans/2026-11-20-foundation.md` · Spec: `docs/superpowers/specs/2026-11-20-foundation-design.md`

| CL | Branch | Base | Plan tasks | Size | Status | Review |
|---|---|---|---|---|---|---|
| 1 | `feature/CL-1-test-target-day-keys` | `main` | 1–2 | 481 | reviewed, PR #1 open | done — concurrency clean; SOLID: 3 fixes + convention sync (below) |
| 2 | `feature/CL-2-apartment-workday` | 1 | 3–4 | ~455 | built, tests green | **NEXT** — `swift-concurrency-pro` + SOLID |
| 3 | `feature/CL-3-timer-stats` | 2 | 5–6 | ~335 | built, tests green | to do — `swift-concurrency-pro` + SOLID |
| 4 | `feature/CL-4-report-formatters` | 3 | 7–8 | ~275 | built, tests green | to do — SOLID (pure formatting) |
| 5 | `feature/CL-5-repositories` | 4 | 9 | ~450 est. | contract tests drafted and committed (red); implementation to do | after build — `swift-concurrency-pro` (streams, `StoreObservers`) + SOLID |
| 6 | `feature/CL-6-swiftdata` | 5 | 10 | ~450 est. | to do (create from 5) | after build — `swift-concurrency-pro` (`@Model` isolation) + SOLID |
| 7 | `feature/CL-7-app-wiring` | 6 | 11 | ~150 est. (end of feature) | to do (create from 6) | after build — `swiftui-pro` + SOLID |

Notes for the sessions:

- Branches 1–4 were built in one long session before the branch rules existed; their review has not
  run yet. Review each one in its own fresh session, in order.
- CL-1 review (2026-11-21): `main` merged in for the current conventions. Concurrency: no
  findings (`nonisolated` structs keep their conformances off the main actor). SOLID / clean code:
  `DayKey(_:calendar:)` failed silently to day 0 → `preconditionFailure`; `MonthKey` storage
  bounds duplicated the `yyyymmdd` encoding → derived from `DayKey.storageValue`; the Warsaw test
  calendar fell back to the device time zone → fails instead; `architecture.md` DayKey/Date
  sentence updated as the foundation spec requires. Merged up into CL-2…CL-5 (CL-2–4 tests green).
- Branch 4 is under 300 lines on purpose: it closes the pure-logic half of the foundation.
- Branch 5 starts with the contract tests already written (`CleanLogTests/Repositories/`,
  `CleanLogTests/Support/Repositories+UnderTest.swift`) and failing to build — continue at the
  plan's Task 9, Step 2.
- After branch 7 merges: delete the foundation plan and design files (`CLAUDE.md`), mark the feature
  done here.

Next free branch number: **CL-8**.

## Roadmap (v1)

Each feature: brainstorm → plan (split into 300–500-line branches, written here) → plan review →
branches as above.

1. Foundation — in progress (above).
2. Design system — colour tokens, `.glassSurface`, `.cardSurface`, String Catalog, the `TabView` shell.
3. Apartments (template) — list, form, reorder, archive. Logic, then UI.
4. Today — plan, ticks, timer, empty state, "as yesterday", past and future days. Logic, then UI.
5. Day plan sheet. Logic, then UI.
6. Calendar. Logic, then UI.
7. Statistics. Logic, then UI.
8. Report and WhatsApp. Logic, then UI.
9. Settings and reminders. Logic, then UI.
10. First launch, app icon, Bundle ID, privacy policy, TestFlight.

Later: Live Activity, home-screen widget, iCloud sync, PDF/CSV export.
