import Foundation
import os

private struct MonthActivity {
    let month: MonthKey
    let hasCleanedApartment: Bool
}

@MainActor
final class MonthEndReminderScheduler {
    private let settings: any SettingsRepository
    private let workDays: any WorkDayRepository
    private let center: any ReminderCenter
    private let now: () -> Date
    private let calendar: Calendar
    private let locale: Locale
    private let logger = Logger(subsystem: "CleanLog", category: "MonthEndReminderScheduler")
    private var latestSettings: MonthEndReminderSettings?
    private var latestActivity: MonthActivity?
    private var needsReschedule = false
    private var isRescheduling = false

    init(
        settings: any SettingsRepository,
        workDays: any WorkDayRepository,
        center: any ReminderCenter,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.settings = settings
        self.workDays = workDays
        self.center = center
        self.now = now
        self.calendar = calendar
        self.locale = locale
    }

    func observeSettings() async {
        for await reminderSettings in settings.monthEndReminder() {
            latestSettings = reminderSettings
            await reschedule()
        }
    }

    func observeDays(in month: MonthKey) async {
        for await days in workDays.days(in: month) {
            latestActivity = MonthActivity(month: month, hasCleanedApartment: days.contains(where: \.hasCleanedEntries))
            await reschedule()
        }
    }

    private func reschedule() async {
        needsReschedule = true
        guard !isRescheduling else { return }
        isRescheduling = true
        defer { isRescheduling = false }
        while needsReschedule {
            needsReschedule = false
            await applyLatestState()
        }
    }

    private func applyLatestState() async {
        guard let latestSettings, let latestActivity else { return }
        let reminder = MonthEndReminder.next(
            settings: latestSettings,
            month: latestActivity.month,
            hasCleanedApartment: latestActivity.hasCleanedApartment,
            now: now(),
            calendar: calendar
        )
        guard let reminder else {
            center.cancelReminder()
            return
        }
        do {
            try await center.schedule(ReminderRequest(reminder, calendar: calendar, locale: locale))
        } catch {
            logger.error("Could not schedule the month-end reminder: \(error.localizedDescription)")
        }
    }
}
