#if DEBUG
    import Foundation

    enum SettingsPreviewData {
        static let off = MonthEndReminderSettings.initial
        static let onAtSix = MonthEndReminderSettings(isOn: true, time: ReminderTime(hour: 18, minute: 0))

        static func viewModel(
            _ reminder: MonthEndReminderSettings,
            authorization: NotificationAuthorization = .authorized
        ) -> SettingsViewModel {
            SettingsViewModel(
                settings: FakeSettingsRepository(reminder),
                permission: FakeNotificationPermission(authorization),
                version: AppVersion(number: "1.0", build: "7")
            )
        }
    }
#endif
