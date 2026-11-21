import Foundation

nonisolated struct ApartmentCount: Sendable, Hashable {
    let apartmentID: UUID
    let name: String
    let count: Int
}

nonisolated struct MonthStats: Sendable, Equatable {
    private static let topApartmentsLimit = 3
    private static let secondsPerHour = 3600

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
        let workedDurations = days.map { $0.workedDuration(now: now) }

        return MonthStats(
            earned: earned,
            cleanedCount: days.map(\.cleanedCount).reduce(0, +),
            workingDays: workingDays,
            workedDuration: workedDurations.reduce(.zero, +),
            earningsPerHour: earningsPerHour(earned: days.map(\.earned), worked: workedDurations),
            averagePerWorkingDay: average(of: earned, over: workingDays),
            topApartments: topApartments(in: days)
        )
    }

    private static func earningsPerHour(earned: [Money], worked: [Duration]) -> Money? {
        let timedDays = zip(earned, worked).filter { _, worked in worked > .zero }
        let timedSeconds = Int(timedDays.map { _, worked in worked.components.seconds }.reduce(0, +))
        guard timedSeconds > 0 else { return nil }
        let timedEarned = timedDays.map { earned, _ in earned }.sum()
        return Money(minorUnits: dividedRoundingHalfUp(timedEarned.minorUnits * secondsPerHour, by: timedSeconds))
    }

    private static func average(of earned: Money, over workingDays: Int) -> Money? {
        guard workingDays > 0 else { return nil }
        return Money(minorUnits: dividedRoundingHalfUp(earned.minorUnits, by: workingDays))
    }

    private static func topApartments(in days: [WorkDay]) -> [ApartmentCount] {
        let cleaned = days.sorted { $0.day < $1.day }.flatMap { $0.entries.filter(\.isCleaned) }
        var tallies: [UUID: ApartmentCount] = [:]
        for entry in cleaned {
            tallies[entry.apartmentID] = ApartmentCount(
                apartmentID: entry.apartmentID,
                name: entry.name,
                count: (tallies[entry.apartmentID]?.count ?? 0) + 1
            )
        }
        let ranked = tallies.values.sorted { lhs, rhs in
            lhs.count != rhs.count ? lhs.count > rhs.count : lhs.name < rhs.name
        }
        return Array(ranked.prefix(topApartmentsLimit))
    }

    private static func dividedRoundingHalfUp(_ numerator: Int, by denominator: Int) -> Int {
        (numerator * 2 + denominator) / (denominator * 2)
    }
}
