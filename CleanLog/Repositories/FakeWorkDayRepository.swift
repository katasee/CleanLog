#if DEBUG
    import Foundation

    final class FakeWorkDayRepository: WorkDayRepository {
        private var stored: [DayKey: WorkDay]
        private let observers = StoreObservers()

        init(_ days: [WorkDay] = []) {
            stored = Dictionary(uniqueKeysWithValues: days.map { ($0.day, $0) })
        }

        func day(_ day: DayKey) -> AsyncStream<WorkDay> {
            observers.stream { [unowned self] in stored[day] ?? .empty(day) }
        }

        func days(in month: MonthKey) -> AsyncStream<[WorkDay]> {
            observers.stream { [unowned self] in
                stored.values
                    .filter { month.contains($0.day) }
                    .sorted { $0.day < $1.day }
            }
        }

        func latestDayWithEntries(before day: DayKey) async throws -> WorkDay? {
            stored.values
                .filter { $0.day < day && !$0.entries.isEmpty }
                .max { $0.day < $1.day }
        }

        func update(_ day: DayKey, _ change: (WorkDay) throws -> WorkDay) async throws {
            let current = stored[day]
            let changed = try change(current ?? .empty(day))
            guard current != nil || !changed.isBlank else { return }
            stored[day] = changed
            observers.notify()
        }
    }
#endif
