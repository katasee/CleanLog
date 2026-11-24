#if DEBUG
    import Foundation

    enum TodayPreviewData {
        static let today = DayKey(.now, calendar: .current)

        static let template: [Apartment] = [
            apartment("100", minorUnits: 2800, accessCode: "4821"),
            apartment("101", minorUnits: 2800, accessCode: "1937"),
            apartment("102", minorUnits: 2800, accessCode: nil),
            apartment("106", minorUnits: 5600, accessCode: "7409"),
        ]

        static func dependencies(_ days: [WorkDay] = []) -> AppDependencies {
            AppDependencies.preview(
                apartments: FakeApartmentRepository(template),
                workDays: FakeWorkDayRepository(days)
            )
        }

        static func day(
            _ day: DayKey = today,
            sessions: [WorkSession] = [],
            isTimerFinished: Bool = false
        ) -> WorkDay {
            var workDay = WorkDay.empty(day).planning(template)
            workDay.entries[0].isCleaned = true
            workDay.sessions = sessions
            workDay.isTimerFinished = isTimerFinished
            return workDay
        }

        static func session(startedHoursAgo hours: Double, endedHoursAgo endHours: Double? = nil) -> WorkSession {
            WorkSession(
                id: UUID(),
                start: .now.addingTimeInterval(-hours * 3600),
                end: endHours.map { .now.addingTimeInterval(-$0 * 3600) }
            )
        }

        private static func apartment(_ name: String, minorUnits: Int, accessCode: String?) -> Apartment {
            Apartment(
                id: UUID(),
                name: name,
                price: Money(minorUnits: minorUnits),
                accessCode: accessCode,
                isReportedSeparately: minorUnits > 2800,
                createdAt: .now
            )
        }
    }
#endif
