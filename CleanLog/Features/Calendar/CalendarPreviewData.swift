#if DEBUG
    import Foundation

    enum CalendarPreviewData {
        static let today = DayKey(.now, calendar: .current)

        private static let names = ["100", "101", "102", "105", "115", "138", "6piw"]
        private static let template: [Apartment] = names.map { apartment($0) }

        static func workDays() -> FakeWorkDayRepository {
            let pastDays = (1..<today.day).map { DayKey(year: today.year, month: today.month, day: $0) }
            let cleanedDays = pastDays.filter { $0.day % 7 != 0 }.map { cleaned($0) }
            let tomorrow = WorkDay.empty(today.adding(days: 1, calendar: .current)).planning(template)
            return FakeWorkDayRepository(cleanedDays + [tomorrow])
        }

        private static func cleaned(_ day: DayKey) -> WorkDay {
            var workDay = WorkDay.empty(day).planning(Array(template.prefix(3 + day.day % 5)))
            for index in workDay.entries.indices {
                workDay.entries[index].isCleaned = true
            }
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
