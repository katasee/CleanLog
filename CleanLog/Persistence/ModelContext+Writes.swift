import SwiftData

extension ModelContext {
    nonisolated func inserted<Record: PersistentModel>(_ record: Record) -> Record {
        insert(record)
        return record
    }

    func saveOrRollBack() throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}
