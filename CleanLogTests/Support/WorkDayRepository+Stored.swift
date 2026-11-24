import Foundation

@testable import CleanLog

extension WorkDayRepository {
    func stored(_ key: DayKey) async -> WorkDay? {
        for await workDay in day(key) {
            return workDay
        }
        return nil
    }
}
