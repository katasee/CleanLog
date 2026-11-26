import Foundation
import Testing

@testable import CleanLog

enum SettingsKind: CaseIterable, Sendable {
    case fake
    case userDefaults

    func makeRepository(defaults: UserDefaults = .fresh()) -> any SettingsRepository {
        switch self {
        case .fake:
            FakeSettingsRepository()
        case .userDefaults:
            UserDefaultsSettingsRepository(defaults: defaults)
        }
    }
}

extension UserDefaults {
    fileprivate static func fresh() -> UserDefaults {
        guard let defaults = UserDefaults(suiteName: "CleanLogTests.\(UUID())") else {
            preconditionFailure("Cannot create a UserDefaults suite")
        }
        return defaults
    }
}

struct SettingsRepositoryContractTests {
    private let morning = MonthEndReminderSettings(isOn: true, time: ReminderTime(hour: 7, minute: 30))

    @Test(arguments: SettingsKind.allCases)
    func startsWithTheReminderOffAtSix(kind: SettingsKind) async {
        var stream = kind.makeRepository().monthEndReminder().makeAsyncIterator()
        #expect(await stream.next() == .initial)
    }

    @Test(arguments: SettingsKind.allCases)
    func yieldsTheSavedSettings(kind: SettingsKind) async throws {
        let repository = kind.makeRepository()
        var stream = repository.monthEndReminder().makeAsyncIterator()
        _ = await stream.next()

        try await repository.saveMonthEndReminder(morning)

        #expect(await stream.next() == morning)
    }

    @Test func keepsSettingsAcrossInstances() async throws {
        let defaults = UserDefaults.fresh()
        try await SettingsKind.userDefaults.makeRepository(defaults: defaults).saveMonthEndReminder(morning)

        var stream = SettingsKind.userDefaults.makeRepository(defaults: defaults).monthEndReminder()
            .makeAsyncIterator()

        #expect(await stream.next() == morning)
    }

    @Test func fallsBackToTheDefaultOnUnreadableData() async {
        let defaults = UserDefaults.fresh()
        defaults.set(Data("x".utf8), forKey: "settings.monthEndReminder")

        var stream = SettingsKind.userDefaults.makeRepository(defaults: defaults).monthEndReminder()
            .makeAsyncIterator()

        #expect(await stream.next() == .initial)
    }
}
