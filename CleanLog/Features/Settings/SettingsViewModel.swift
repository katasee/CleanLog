import Foundation
import Observation
import os

@Observable @MainActor
final class SettingsViewModel {
    private static let referenceDay = DayKey(year: 2001, month: 1, day: 1)

    private let settings: any SettingsRepository
    private let permission: any NotificationPermission
    private let calendar: Calendar
    private let locale: Locale
    private let logger = Logger(subsystem: "CleanLog", category: "SettingsViewModel")
    private var stored: MonthEndReminderSettings

    let versionText: String
    var isReminderOn: Bool
    var reminderTime: Date
    private(set) var isPermissionDenied = false
    private(set) var errorMessage: String?

    init(
        settings: any SettingsRepository,
        permission: any NotificationPermission,
        version: AppVersion,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.settings = settings
        self.permission = permission
        self.calendar = calendar
        self.locale = locale
        versionText = String(localized: .settingsVersion(version.number, version.build), locale: locale)
        let reminder = MonthEndReminderSettings.initial
        stored = reminder
        isReminderOn = reminder.isOn
        reminderTime = reminder.time.date(on: Self.referenceDay, calendar: calendar)
    }

    var notificationSettingsURL: URL {
        permission.settingsURL
    }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    func observe() async {
        for await reminder in settings.monthEndReminder() {
            show(reminder)
        }
    }

    func refreshPermission() async {
        isPermissionDenied = await permission.authorization() == .denied
    }

    func reminderSwitchChanged() async {
        guard isReminderOn != stored.isOn else { return }
        guard isReminderOn else {
            await save { $0.isOn = false }
            return
        }
        guard await isNotificationAllowed(), isReminderOn else {
            show(stored)
            return
        }
        await save { $0.isOn = true }
    }

    func reminderTimeChanged() async {
        let time = ReminderTime(reminderTime, calendar: calendar)
        guard time != stored.time else { return }
        await save { $0.time = time }
    }

    private func isNotificationAllowed() async -> Bool {
        let isAllowed =
            switch await permission.authorization() {
            case .authorized: true
            case .denied: false
            case .notDetermined: await requestAuthorization()
            }
        isPermissionDenied = !isAllowed
        return isAllowed
    }

    private func requestAuthorization() async -> Bool {
        do {
            return try await permission.requestAuthorization()
        } catch {
            logger.error("Could not ask for notification permission: \(error)")
            return false
        }
    }

    private func save(_ change: (inout MonthEndReminderSettings) -> Void) async {
        let previous = stored
        change(&stored)
        do {
            try await settings.saveMonthEndReminder(stored)
        } catch {
            logger.error("Could not save the reminder settings: \(error)")
            errorMessage = String(localized: .settingsErrorSave, locale: locale)
            show(previous)
        }
    }

    private func show(_ reminder: MonthEndReminderSettings) {
        stored = reminder
        isReminderOn = reminder.isOn
        reminderTime = reminder.time.date(on: Self.referenceDay, calendar: calendar)
    }
}
