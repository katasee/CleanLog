import Foundation
import Testing

@testable import CleanLog

struct SettingsViewModelTests {
    private let morning = MonthEndReminderSettings(isOn: true, time: ReminderTime(hour: 7, minute: 30))
    private let referenceDay = DayKey(year: 2001, month: 1, day: 1)

    private func makeViewModel(
        settings: any SettingsRepository = FakeSettingsRepository(),
        permission: any NotificationPermission = FakeNotificationPermission(),
        version: AppVersion = AppVersion(number: "1.0", build: "7"),
        locale: Locale = Locale(identifier: "uk_UA")
    ) -> SettingsViewModel {
        SettingsViewModel(
            settings: settings,
            permission: permission,
            version: version,
            calendar: .warsaw,
            locale: locale
        )
    }

    private func observing(
        _ viewModel: SettingsViewModel,
        _ body: () async throws -> Void
    ) async rethrows {
        let observation = Task { await viewModel.observe() }
        defer { observation.cancel() }
        try await body()
    }

    private func stored(in repository: any SettingsRepository) async -> MonthEndReminderSettings? {
        var stream = repository.monthEndReminder().makeAsyncIterator()
        return await stream.next()
    }

    private func turnOn(_ viewModel: SettingsViewModel) async {
        viewModel.isReminderOn = true
        await viewModel.reminderSwitchChanged()
    }

    @Test func showsTheStoredSettings() async {
        let viewModel = makeViewModel(settings: FakeSettingsRepository(morning))

        await observing(viewModel) {
            await eventually { viewModel.isReminderOn }
            let time = Calendar.warsaw.dateComponents([.hour, .minute], from: viewModel.reminderTime)
            #expect(time.hour == 7)
            #expect(time.minute == 30)
        }
    }

    @Test func turningOnAsksForPermissionOnce() async {
        let settings = FakeSettingsRepository()
        let permission = FakeNotificationPermission(.notDetermined)
        let viewModel = makeViewModel(settings: settings, permission: permission)

        await turnOn(viewModel)
        #expect(await stored(in: settings)?.isOn == true)
        #expect(permission.requestCount == 1)
        #expect(!viewModel.isPermissionDenied)
    }

    @Test func turningOnWhenAuthorizedDoesNotAsk() async {
        let settings = FakeSettingsRepository()
        let permission = FakeNotificationPermission(.authorized)
        let viewModel = makeViewModel(settings: settings, permission: permission)

        await turnOn(viewModel)
        #expect(await stored(in: settings)?.isOn == true)
        #expect(permission.requestCount == 0)
    }

    @Test func refusedPermissionKeepsItOff() async {
        let settings = FakeSettingsRepository()
        let permission = FakeNotificationPermission(.notDetermined, grants: false)
        let viewModel = makeViewModel(settings: settings, permission: permission)

        await turnOn(viewModel)
        #expect(await stored(in: settings)?.isOn == false)
        #expect(!viewModel.isReminderOn)
        #expect(viewModel.isPermissionDenied)
    }

    @Test func deniedPermissionShowsTheRowWithoutAsking() async {
        let settings = FakeSettingsRepository()
        let permission = FakeNotificationPermission(.denied)
        let viewModel = makeViewModel(settings: settings, permission: permission)

        await turnOn(viewModel)
        #expect(permission.requestCount == 0)
        #expect(await stored(in: settings)?.isOn == false)
        #expect(!viewModel.isReminderOn)
        #expect(viewModel.isPermissionDenied)
    }

    @Test func openingWithRevokedPermissionKeepsTheReminderOn() async {
        let settings = FakeSettingsRepository(morning)
        let viewModel = makeViewModel(settings: settings, permission: FakeNotificationPermission(.denied))

        await observing(viewModel) {
            await eventually { viewModel.isReminderOn }
            await viewModel.refreshPermission()
            await viewModel.reminderSwitchChanged()
            #expect(await stored(in: settings) == morning)
            #expect(viewModel.isReminderOn)
            #expect(viewModel.isPermissionDenied)
        }
    }

    @Test func turningOffSavesWithoutAsking() async {
        let settings = FakeSettingsRepository(morning)
        let permission = FakeNotificationPermission(.notDetermined)
        let viewModel = makeViewModel(settings: settings, permission: permission)

        await observing(viewModel) {
            await eventually { viewModel.isReminderOn }
            viewModel.isReminderOn = false
            await viewModel.reminderSwitchChanged()
            #expect(await stored(in: settings)?.isOn == false)
            #expect(permission.requestCount == 0)
        }
    }

    @Test func changingTheTimeSavesIt() async {
        let settings = FakeSettingsRepository(morning)
        let viewModel = makeViewModel(settings: settings)

        await observing(viewModel) {
            await eventually { viewModel.isReminderOn }
            viewModel.reminderTime = ReminderTime(hour: 6, minute: 45).date(on: referenceDay, calendar: .warsaw)
            await viewModel.reminderTimeChanged()
            let expected = MonthEndReminderSettings(isOn: true, time: ReminderTime(hour: 6, minute: 45))
            #expect(await stored(in: settings) == expected)
        }
    }

    @Test func refreshShowsAndHidesTheDeniedRow() async {
        let permission = FakeNotificationPermission(.denied)
        let viewModel = makeViewModel(permission: permission)

        await viewModel.refreshPermission()
        #expect(viewModel.isPermissionDenied)

        permission.set(.authorized)
        await viewModel.refreshPermission()
        #expect(!viewModel.isPermissionDenied)
    }

    @Test func failedSaveShowsTheError() async {
        let viewModel = makeViewModel(settings: FailingSettingsRepository())

        await turnOn(viewModel)
        #expect(viewModel.errorMessage == "Не вдалося зберегти налаштування")
        #expect(viewModel.isShowingError)
        #expect(!viewModel.isReminderOn)
    }

    @Test func showsTheVersion() {
        #expect(makeViewModel().versionText == "Версія 1.0 (7)")
        #expect(makeViewModel(locale: Locale(identifier: "en_US")).versionText == "Version 1.0 (7)")
    }
}
