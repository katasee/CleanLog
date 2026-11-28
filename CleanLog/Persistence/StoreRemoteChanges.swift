import CoreData
import Foundation

nonisolated enum StoreRemoteChanges {
    static func signals() -> AsyncStream<Void> {
        NotificationCenter.default.forwarded(
            .NSPersistentStoreRemoteChange,
            bufferingPolicy: .bufferingNewest(1)
        ) { _ in () }
    }
}
