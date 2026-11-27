import Foundation
import SwiftData

final class StoreDuplicateMerger {
    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    func mergeDuplicates() throws -> Bool {
        let survivorIDs = try mergeApartments()
        let repointedDays = try daysReferencing(Array(survivorIDs.keys))
        try mergeDays(repointing: survivorIDs, alsoMerging: repointedDays)
        guard context.hasChanges else { return false }
        try context.saveOrRollBack()
        return true
    }

    private var context: ModelContext {
        container.mainContext
    }

    private func mergeApartments() throws -> [UUID: UUID] {
        let records = try context.fetch(FetchDescriptor<ApartmentRecord>())
        var survivorIDs: [UUID: UUID] = [:]
        for merge in ApartmentDuplicates.merges(in: records.map(\.revision)) {
            let survivorID = merge.survivor.value.id
            for record in records where merge.removedIDs.contains(record.id) {
                context.delete(record)
            }
            records.first { $0.id == survivorID }?.apply(merge.survivor)
            for removedID in merge.removedIDs {
                survivorIDs[removedID] = survivorID
            }
        }
        return survivorIDs
    }

    private func daysReferencing(_ apartmentIDs: [UUID]) throws -> Set<Int> {
        guard !apartmentIDs.isEmpty else { return [] }
        let descriptor = FetchDescriptor<DayEntryRecord>(
            predicate: #Predicate { apartmentIDs.contains($0.apartmentID) }
        )
        return Set(try context.fetch(descriptor).compactMap(\.day?.dayValue))
    }

    private func mergeDays(repointing survivorIDs: [UUID: UUID], alsoMerging repointedDays: Set<Int>) throws {
        let records = try context.fetch(FetchDescriptor<WorkDayRecord>())
        for (dayValue, copies) in Dictionary(grouping: records, by: \.dayValue)
        where copies.count > 1 || repointedDays.contains(dayValue) {
            merge(copies, repointing: survivorIDs)
        }
    }

    private func merge(_ copies: [WorkDayRecord], repointing survivorIDs: [UUID: UUID]) {
        let merged = WorkDayDuplicates.merged(copies.map { repointed($0.revision, survivorIDs) })
        for record in copies where record.id != merged.value.id {
            context.delete(record)
        }
        copies.first { $0.id == merged.value.id }?.apply(merged)
    }

    private func repointed(_ revision: Revision<WorkDay>, _ survivorIDs: [UUID: UUID]) -> Revision<WorkDay> {
        var copy = revision
        copy.value.entries = revision.value.entries.map { entry in
            survivorIDs[entry.apartmentID].map(entry.pointing(to:)) ?? entry
        }
        return copy
    }
}
