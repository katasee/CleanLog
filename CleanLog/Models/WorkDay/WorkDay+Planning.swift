import Foundation

extension WorkDay {
    /// Adds an entry for each apartment that is not on the day yet.
    nonisolated func planning(_ apartments: [Apartment]) -> WorkDay {
        appending(apartments.map(DayEntry.init(planning:)))
    }

    /// Plans the apartments of `other`, unticked, from its snapshots — an apartment archived since
    /// is still copied, because it really was on that day.
    nonisolated func copyingPlan(from other: WorkDay) -> WorkDay {
        appending(other.entries.map { $0.replanned() })
    }

    nonisolated func removingEntry(_ id: DayEntry.ID) -> WorkDay {
        var copy = self
        copy.entries.removeAll { $0.id == id }
        return copy
    }

    nonisolated func settingCleaned(
        _ entryID: DayEntry.ID,
        _ isCleaned: Bool,
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

    private nonisolated func appending(_ newEntries: [DayEntry]) -> WorkDay {
        var copy = self
        for entry in newEntries where !copy.entries.contains(where: { $0.apartmentID == entry.apartmentID }) {
            copy.entries.append(entry)
        }
        return copy
    }
}
