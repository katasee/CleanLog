import Foundation

nonisolated struct ApartmentCount: Sendable, Hashable {
    let apartmentID: UUID
    let name: String
    let count: Int
}

nonisolated struct MonthStats: Sendable, Equatable {
    private static let topApartmentsLimit = 3

    let earned: Money
    let cleanedCount: Int
    let workingDays: Int
    let workedDuration: Duration
    let earningsPerHour: Money?
    let averagePerWorkingDay: Money?
    let topApartments: [ApartmentCount]

    static func calculate(days: [WorkDay], now: Date) -> MonthStats {
        let earned = days.map(\.earned).sum()
        let workingDays = days.count(where: \.hasCleanedEntries)
        let timedDays = days.filter { $0.workedDuration(now: now) > .zero }
        let timedSeconds = timedDays.map { $0.workedDuration(now: now).components.seconds }.reduce(0, +)
        let timedEarned = timedDays.map(\.earned).sum()

        return MonthStats(
            earned: earned,
            cleanedCount: days.map(\.cleanedCount).reduce(0, +),
            workingDays: workingDays,
            workedDuration: days.reduce(.zero) { $0 + $1.workedDuration(now: now) },
            earningsPerHour: timedSeconds > 0
                ? Money(minorUnits: dividedRoundingHalfUp(timedEarned.minorUnits * 3600, by: Int(timedSeconds)))
                : nil,
            averagePerWorkingDay: workingDays > 0
                ? Money(minorUnits: dividedRoundingHalfUp(earned.minorUnits, by: workingDays))
                : nil,
            topApartments: topApartments(in: days)
        )
    }

    private static func topApartments(in days: [WorkDay]) -> [ApartmentCount] {
        let cleaned = days.sorted { $0.day < $1.day }.flatMap { $0.entries.filter(\.isCleaned) }
        let counts = Dictionary(grouping: cleaned, by: \.apartmentID).map { id, entries in
            ApartmentCount(apartmentID: id, name: entries.last?.name ?? "", count: entries.count)
        }
        let ranked = counts.sorted { lhs, rhs in
            lhs.count != rhs.count ? lhs.count > rhs.count : lhs.name < rhs.name
        }
        return Array(ranked.prefix(topApartmentsLimit))
    }

    private static func dividedRoundingHalfUp(_ numerator: Int, by denominator: Int) -> Int {
        (numerator * 2 + denominator) / (denominator * 2)
    }
}
