import Foundation
import Observation
import SwiftData

@Observable
final class AppDependencies {
    let apartments: any ApartmentRepository
    let workDays: any WorkDayRepository
    let settings: any SettingsRepository
    let urlAvailability: any URLAvailability
    let pasteboard: any Pasteboard
    let reminderScheduler: MonthEndReminderScheduler
    let notificationPermission: any NotificationPermission
    let appVersion: AppVersion

    private init(
        apartments: any ApartmentRepository,
        workDays: any WorkDayRepository,
        settings: any SettingsRepository,
        urlAvailability: any URLAvailability,
        pasteboard: any Pasteboard,
        reminderCenter: any ReminderCenter,
        notificationPermission: any NotificationPermission,
        appVersion: AppVersion
    ) {
        self.apartments = apartments
        self.workDays = workDays
        self.settings = settings
        self.urlAvailability = urlAvailability
        self.pasteboard = pasteboard
        reminderScheduler = MonthEndReminderScheduler(
            settings: settings,
            workDays: workDays,
            center: reminderCenter
        )
        self.notificationPermission = notificationPermission
        self.appVersion = appVersion
    }

    static func live() throws -> AppDependencies {
        let container = try ModelContainerFactory.make(inMemory: false)
        let notifications = SystemNotifications()
        return AppDependencies(
            apartments: SwiftDataApartmentRepository(container: container),
            workDays: SwiftDataWorkDayRepository(container: container),
            settings: UserDefaultsSettingsRepository(defaults: .standard),
            urlAvailability: SystemURLAvailability(),
            pasteboard: SystemPasteboard(),
            reminderCenter: notifications,
            notificationPermission: notifications,
            appVersion: AppVersion(bundle: .main)
        )
    }
}

#if DEBUG
    extension AppDependencies {
        static func preview(
            apartments: any ApartmentRepository = FakeApartmentRepository(),
            workDays: any WorkDayRepository = FakeWorkDayRepository(),
            settings: any SettingsRepository = FakeSettingsRepository(),
            urlAvailability: any URLAvailability = FakeURLAvailability(),
            pasteboard: any Pasteboard = FakePasteboard(),
            reminderCenter: any ReminderCenter = FakeReminderCenter(),
            notificationPermission: any NotificationPermission = FakeNotificationPermission(),
            appVersion: AppVersion = AppVersion(number: "1.0", build: "1")
        ) -> AppDependencies {
            AppDependencies(
                apartments: apartments,
                workDays: workDays,
                settings: settings,
                urlAvailability: urlAvailability,
                pasteboard: pasteboard,
                reminderCenter: reminderCenter,
                notificationPermission: notificationPermission,
                appVersion: appVersion
            )
        }
    }
#endif
