import SwiftData

extension ModelContext {
    func saveOrRollBack() throws {
        do {
            try save()
        } catch {
            rollback()
            throw error
        }
    }
}
