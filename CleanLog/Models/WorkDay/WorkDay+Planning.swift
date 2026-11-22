import Foundation

extension WorkDay {
    nonisolated func planning(_ apartments: [Apartment]) -> WorkDay {
        addingUnplanned(apartments.map(DayEntry.init(planning:)))
    }

    nonisolated func copyingPlan(from other: WorkDay, template: [Apartment]) -> WorkDay {
        let apartments = other.entries.compactMap { entry in
            template.first { $0.id == entry.apartmentID }
        }
        return planning(apartments)
    }

    nonisolated func removingEntry(_ id: DayEntry.ID) -> WorkDay {
        var copy = self
        copy.entries.removeAll { $0.id == id }
        return copy
    }

    nonisolated func settingCleaned(
        _ entryID: DayEntry.ID,
        to isCleaned: Bool,
        now: Date,
        today: DayKey
    ) throws(WorkDayError) -> WorkDay {
        guard day <= today else { throw .futureDay }
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { throw .entryNotFound }
        var copy = self
        copy.entries[index].isCleaned = isCleaned
        copy.entries[index].cleanedAt = isCleaned ? now : nil
        return copy
    }

    private nonisolated func addingUnplanned(_ newEntries: [DayEntry]) -> WorkDay {
        var copy = self
        for entry in newEntries where !copy.entries.contains(where: { $0.apartmentID == entry.apartmentID }) {
            copy.entries.append(entry)
        }
        return copy
    }
}
