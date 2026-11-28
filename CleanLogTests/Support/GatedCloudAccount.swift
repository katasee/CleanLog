@testable import CleanLog

final class GatedCloudAccount: CloudAccount {
    private var waiting: [CheckedContinuation<Void, Never>] = []

    var hasWaitingCheck: Bool {
        !waiting.isEmpty
    }

    func open() {
        waiting.forEach { $0.resume() }
        waiting = []
    }

    func status() async -> CloudStatus {
        await withCheckedContinuation { waiting.append($0) }
        return .synced
    }
}
