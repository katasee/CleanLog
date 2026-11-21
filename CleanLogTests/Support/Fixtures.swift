import Foundation

@testable import CleanLog

extension Apartment {
    static func fixture(
        _ name: String,
        minorUnits: Int = 2800,
        separate: Bool = false
    ) -> Apartment {
        Apartment(
            id: UUID(),
            name: name,
            price: Money(minorUnits: minorUnits),
            accessCode: nil,
            isReportedSeparately: separate,
            createdAt: .warsaw(2026, 11, 1)
        )
    }
}

extension WorkDay {
    static func fixture(_ day: DayKey, ticked: [Apartment], unticked: [Apartment] = []) -> WorkDay {
        let tickedIDs = Set(ticked.map(\.id))
        var workDay = WorkDay.empty(day).planning(ticked + unticked)
        for index in workDay.entries.indices where tickedIDs.contains(workDay.entries[index].apartmentID) {
            workDay.entries[index].isCleaned = true
        }
        return workDay
    }
}
