nonisolated enum CloudStatus: Sendable, Equatable {
    case synced
    case local
    case storageFull
}

protocol CloudAccount: AnyObject {
    func status() async -> CloudStatus
}

#if DEBUG
    final class FakeCloudAccount: CloudAccount {
        private var current: CloudStatus

        init(status: CloudStatus = .synced) {
            current = status
        }

        func set(_ status: CloudStatus) {
            current = status
        }

        func status() async -> CloudStatus {
            current
        }
    }
#endif
