import CloudKit
import CoreData
import Observation

nonisolated enum CloudUploadOutcome: Sendable, Equatable {
    case succeeded
    case storageFull
    case failed

    init(error: (any Error)?) {
        guard let error else {
            self = .succeeded
            return
        }
        self = Self.isQuotaExceeded(error) ? .storageFull : .failed
    }

    private static func isQuotaExceeded(_ error: any Error) -> Bool {
        guard let cloudError = error as? CKError else { return false }
        if cloudError.code == .quotaExceeded {
            return true
        }
        guard let itemErrors = cloudError.partialErrorsByItemID?.values else { return false }
        return itemErrors.contains { ($0 as? CKError)?.code == .quotaExceeded }
    }
}

@Observable
final class CloudUploadMonitor {
    private let outcomes: () -> AsyncStream<CloudUploadOutcome>

    private(set) var isStorageFull = false

    init(outcomes: @escaping () -> AsyncStream<CloudUploadOutcome> = CloudUploadMonitor.exportOutcomes) {
        self.outcomes = outcomes
    }

    func run() async {
        for await outcome in outcomes() {
            record(outcome)
        }
    }

    private func record(_ outcome: CloudUploadOutcome) {
        switch outcome {
        case .succeeded: isStorageFull = false
        case .storageFull: isStorageFull = true
        case .failed: break
        }
    }

    nonisolated static func exportOutcomes() -> AsyncStream<CloudUploadOutcome> {
        let (stream, continuation) = AsyncStream.makeStream(of: CloudUploadOutcome.self)
        let forwarding = Task {
            let events = NotificationCenter.default.notifications(
                named: NSPersistentCloudKitContainer.eventChangedNotification
            )
            for await notification in events {
                let key = NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                guard let event = notification.userInfo?[key] as? NSPersistentCloudKitContainer.Event,
                    event.type == .export,
                    event.endDate != nil
                else { continue }
                continuation.yield(CloudUploadOutcome(error: event.error))
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in
            forwarding.cancel()
        }
        return stream
    }
}
