#if DEBUG
    import Foundation

    enum StatsPreviewData {
        private static let today = DayKey(.now, calendar: .current)

        private static let names = ["100", "101", "102", "105", "115", "138", "6piw"]
        private static let template: [Apartment] = names.map { apartment($0) }

        static func workDays() -> FakeWorkDayRepository {
            let previousMonth = today.monthKey.previous
            let currentDays = (1..<today.day).map { DayKey(year: today.year, month: today.month, day: $0) }
            let previousDays = (1...28).map { DayKey(year: previousMonth.year, month: previousMonth.month, day: $0) }
            let workingDays = (currentDays + previousDays).filter { $0.day % 7 != 0 }
            return FakeWorkDayRepository(workingDays.map { worked($0) })
        }

        private static func worked(_ day: DayKey) -> WorkDay {
            var workDay = WorkDay.empty(day).planning(Array(template.prefix(2 + day.day % 4)))
            for index in workDay.entries.indices {
                workDay.entries[index].isCleaned = true
            }
            workDay.manualDuration = .seconds(3600 * (3 + day.day % 3))
            return workDay
        }

        private static func apartment(_ name: String) -> Apartment {
            Apartment(
                id: UUID(),
                name: name,
                price: Money(minorUnits: 2800),
                accessCode: nil,
                isReportedSeparately: false,
                createdAt: .now
            )
        }
    }
#endif
