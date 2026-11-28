import CoreData
import Foundation

nonisolated enum StoreRemoteChanges {
    static func signals() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let forwarding = Task {
            for await _ in NotificationCenter.default.notifications(named: .NSPersistentStoreRemoteChange) {
                continuation.yield()
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in
            forwarding.cancel()
        }
        return stream
    }
}
