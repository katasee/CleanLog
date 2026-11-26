# Settings and reminders — design

Feature 9 of the roadmap. Product spec: `docs/superpowers/specs/2026-11-13-cleanlog-design.md` (Settings).
Visual reference: there is **no Settings artboard** on the design canvas (checked 2026-11-26); the `Apartments`
artboard draws the button that opens it (a round glass button, labelled «Налаштування», trailing in the header).
The screen follows the existing screens instead: `Card` rows on the screen background, a system navigation bar
and a close button as on the Report and Calendar sheets. Builds on `WorkDayRepository.days(in:)`, `StoreObservers`,
`DayFormat.monthInTitle` and the Report sheet (`ReportView(month:today:dependencies:)`, Feature 8).

## Intent

The report goes to the boss at the end of the month, and the month's end is easy to miss. A local notification
on the last day of the month, at a time she picks, reminds her to send it; tapping it opens that month's report,
one tap from WhatsApp. Settings is the place where she turns the reminder on and picks the time.

## Goals

- A settings button in the Apartments toolbar opens a Settings sheet; there is no Settings tab.
- Settings has one switch, «Нагадати надіслати звіт», **off by default**. When it is on, a time picker
  («Час») appears; the time starts at 18:00.
- Turning the switch on asks for notification permission the first time. A refusal leaves the switch off.
- When notifications are denied for the app, Settings says so in a row with a button that opens the app's page
  in the system Settings.
- Settings shows the app's version and build at the bottom («Версія 1.0 (7)»).
- With the reminder on, a notification arrives on the last day of the month at the chosen time — but only for a
  month with at least one cleaned apartment.
- Tapping the notification opens the Statistics tab with that month's report sheet.

## Non-goals

- A morning reminder to plan the day (removed from v1 on 2026-11-26).
- The iCloud status line (Feature 10) and the privacy policy link (Feature 11).
- A currency, language or appearance setting: the app follows the system for language and appearance, and is
  złoty-only.
- Syncing the reminder settings through iCloud: on a new phone she switches the reminder on again (the
  notification permission has to be granted again there anyway).
- More than one reminder, a reminder on another day than the last, or a repeat when she ignores it.

## Anti-goals

- A reminder for a month in which she cleaned nothing.
- A permission prompt before she asks for the reminder.
- A switch that shows «on» while the system will never deliver the notification without saying why.
- Opening Settings wiping a stored «on» because the permission was revoked meanwhile.

## Decisions taken in the brainstorm (2026-11-26)

1. **Settings opens from a toolbar button on Apartments**, as the product spec says; no new tab.
2. **The month-end reminder is off by default.** She turns it on in Settings and picks the time.
3. **No morning reminder in v1.**
4. **The iCloud status line and the privacy policy row are not in Settings yet**; Features 10 and 11 add them.

Proposed in the brainstorm and taken as decisions here (the user may still correct them):

5. **The time starts at 18:00** when she first turns the reminder on; the day is always the last day of the month.
6. **A month with no cleaned apartment gets no reminder.**
7. **Tapping the notification opens that month's report sheet** (on the Statistics tab).
8. **The reminder settings live in `UserDefaults`** behind a `SettingsRepository`, not in SwiftData and not synced.
9. **When notification permission is denied**, Settings shows a row with a button that opens the system settings.

Claude's calls (the user may correct them):

10. **The settings button uses the `slider.horizontal.3` glyph**, the SF Symbol closest to the sliders the
    `Apartments` artboard draws (the canvas is the reference for every screen); it follows the artboard and the
    user has not confirmed it yet.
11. **Denied permission keeps a stored «on».** If she revokes the permission in iOS after turning the reminder
    on, the switch stays on, the denied row appears, and the reminder works again once she allows notifications.
    Turning the switch on while permission is denied does not change the setting; it shows the row.
12. **A notification that arrives while the app is open is shown as a banner** as well.
13. **The version row** reads «Версія {CFBundleShortVersionString} ({CFBundleVersion})».

## How the reminder is scheduled

iOS cannot express «the last day of every month» as a repeating trigger, and the app cannot check the month's
data when the notification fires. Both are solved by scheduling **one** notification, for the current month only,
and rescheduling it whenever its inputs change:

- The reminder for month M fires on M's last day at the chosen time, as calendar components without a time zone
  (it fires at 18:00 wherever the phone is, like `DayKey`).
- It is scheduled when the reminder is on, M has a cleaned apartment and that moment is still ahead; otherwise
  the pending request is removed. There is one request, under a fixed identifier, so scheduling replaces it.
- Inputs: the reminder settings (a stream from `SettingsRepository`), whether the current month has a cleaned
  apartment (the `days(in:)` stream), and the current month (re-read when the app becomes active).
- Why the current month is enough: a cleaned apartment can only appear while the app is open, and opening the
  app re-reads the month, so every month with a cleaned apartment has had its reminder scheduled. A month in
  which the app was never opened has nothing to report.
- Reschedules are serialized: a change that arrives while a request is being added is applied right after it,
  with the latest state, so a stale request never survives a newer «off».
- A failed `add` is logged (`Logger`); there is no screen to show it on.

## The Settings sheet

```
┌──────────────────────────────────────┐
│ (×)          Налаштування            │   system navigation bar, inline title, close button
│                                      │
│  НАГАДУВАННЯ                         │
│ ┌──────────────────────────────────┐ │
│ │ Нагадати надіслати звіт     (●)  │ │   Card rows
│ │ Час                       18:00  │ │   only when the switch is on
│ └──────────────────────────────────┘ │
│  В останній день місяця, якщо цього  │   section footer
│  місяця є прибрані квартири.         │
│ ┌──────────────────────────────────┐ │
│ │ Сповіщення для CleanLog вимкнені │ │   only when permission is denied
│ │ Відкрити налаштування            │ │
│ └──────────────────────────────────┘ │
│                                      │
│           Версія 1.0 (7)             │   InkSecondary, footnote
└──────────────────────────────────────┘
```

- A `List` with hidden content background on `.screenBackground`, rows on `Card`, the large detent.
- The time picker is a compact `DatePicker` with hours and minutes only; it follows the locale's 12/24-hour clock.
- The permission state is re-read when the sheet appears and when the app returns to the foreground (she may
  come back from the system Settings).
- New strings under `settings.*` and `reminder.*` (the notification), Ukrainian and English; the button on
  Apartments is `apartments.action.settings`.

## The notification

- Title «Час надіслати звіт» / «Time to send the report».
- Body «Звіт за листопад готовий — надішли його у WhatsApp.» / «Your November report is ready to send.», the month
  from `DayFormat.monthInTitle`.
- It carries the month (year and month numbers) so a tap can open its report.

## Changes to existing code

- `ApartmentsView` takes `AppDependencies` (as `StatsView` does) to build the Settings sheet, and gets the toolbar
  button.
- `AppDependencies` gains the settings repository, the notification services, the scheduler and the
  notification responder.
- `RootView` runs the scheduler, switches to Statistics and presents the report sheet when a notification is
  tapped.
- Product spec: Settings section rewritten to the decisions above; the iCloud line and the privacy row moved to
  the roadmap items of Features 10 and 11.

## Testing

- The pure reminder rule: off, nothing cleaned, the last day of a 30-, 31-day month and of February in a leap
  year, the moment just before and exactly at the reminder time.
- `SettingsRepository` against the fake and `UserDefaults` (a fresh suite per test): the default, saving,
  reading back across instances, unreadable stored data.
- The scheduler against fakes: schedule, cancel on off, cancel on an empty month, reschedule on a new time, the
  first tick of the month, and the latest state winning over a request still being added.
- `SettingsViewModel` against fakes: every permission path, saving, the error message, the version text.
- Parsing the month out of a notification's payload.

## Left to the builder

- File names and the split into branches (logic first, then UI) — in the plan.
- The exact `UserNotifications` calls and any Sendable adjustments the compiler asks for.
