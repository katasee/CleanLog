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
        NotificationCenter.default.forwarded(NSPersistentCloudKitContainer.eventChangedNotification) { notification in
            let key = NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            guard let event = notification.userInfo?[key] as? NSPersistentCloudKitContainer.Event,
                event.type == .export,
                event.endDate != nil
            else { return nil }
            return CloudUploadOutcome(error: event.error)
        }
    }
}
