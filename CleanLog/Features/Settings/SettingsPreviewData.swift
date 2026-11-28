#if DEBUG
    import Foundation

    enum SettingsPreviewData {
        static let off = MonthEndReminderSettings.initial
        static let onAtDefaultTime = MonthEndReminderSettings(isOn: true, time: MonthEndReminderSettings.initial.time)

        static func viewModel(
            _ reminder: MonthEndReminderSettings,
            authorization: NotificationAuthorization = .authorized,
            cloud: CloudStatus = .synced
        ) -> SettingsViewModel {
            SettingsViewModel(
                settings: FakeSettingsRepository(reminder),
                permission: FakeNotificationPermission(authorization),
                cloudAccount: FakeCloudAccount(status: cloud),
                version: AppVersion(number: "1.0", build: "7")
            )
        }
    }
#endif
