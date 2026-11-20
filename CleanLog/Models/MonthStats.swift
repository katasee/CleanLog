import Foundation

nonisolated struct ApartmentCount: Sendable, Hashable {
    let apartmentID: UUID
    let name: String
    let count: Int
}

/// A month's numbers, unformatted. The comparison with the previous month is a second `calculate`.
nonisolated struct MonthStats: Sendable, Equatable {
    private static let topApartmentsLimit = 3

    let earned: Money
    /// Every cleaned entry, separately reported ones included.
    let cleanedCount: Int
    /// Days with at least one cleaned entry.
    let workingDays: Int
    let workedDuration: Duration
    /// Earned on days with recorded time, divided by their hours; `nil` without recorded time.
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
                ? Money(grosze: dividedRoundingHalfUp(timedEarned.grosze * 3600, by: Int(timedSeconds)))
                : nil,
            averagePerWorkingDay: workingDays > 0
                ? Money(grosze: dividedRoundingHalfUp(earned.grosze, by: workingDays))
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
