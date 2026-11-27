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
    let reminderResponder = ReminderResponder()
    let notificationPermission: any NotificationPermission
    let appVersion: AppVersion
    let storeSync: StoreSync?

    private init(
        apartments: any ApartmentRepository,
        workDays: any WorkDayRepository,
        settings: any SettingsRepository,
        urlAvailability: any URLAvailability,
        pasteboard: any Pasteboard,
        reminderCenter: any ReminderCenter,
        notificationPermission: any NotificationPermission,
        appVersion: AppVersion,
        storeSync: StoreSync?
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
        self.storeSync = storeSync
    }

    private static let cloudContainerID = "iCloud.com.cleanlog"

    static func live() throws -> AppDependencies {
        let container = try ModelContainerFactory.make(.iCloud(containerID: cloudContainerID))
        let apartments = SwiftDataApartmentRepository(container: container)
        let workDays = SwiftDataWorkDayRepository(container: container)
        let notifications = SystemNotifications()
        let dependencies = AppDependencies(
            apartments: apartments,
            workDays: workDays,
            settings: UserDefaultsSettingsRepository(defaults: .standard),
            urlAvailability: SystemURLAvailability(),
            pasteboard: SystemPasteboard(),
            reminderCenter: notifications,
            notificationPermission: notifications,
            appVersion: AppVersion(bundle: .main),
            storeSync: StoreSync(
                merger: StoreDuplicateMerger(container: container),
                stores: [apartments, workDays]
            )
        )
        notifications.deliverResponses(to: dependencies.reminderResponder)
        return dependencies
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
                appVersion: appVersion,
                storeSync: nil
            )
        }
    }
#endif
