import CloudKit
import os

final class SystemCloudAccount: CloudAccount {
    private let containerID: String
    private let uploads: CloudUploadMonitor
    private let logger = Logger(subsystem: "CleanLog", category: "SystemCloudAccount")

    init(containerID: String, uploads: CloudUploadMonitor) {
        self.containerID = containerID
        self.uploads = uploads
    }

    func status() async -> CloudStatus {
        guard await isAvailable() else { return .local }
        return uploads.isStorageFull ? .storageFull : .synced
    }

    private func isAvailable() async -> Bool {
        do {
            return try await CKContainer(identifier: containerID).accountStatus() == .available
        } catch {
            logger.error("Could not read the iCloud account: \(error)")
            return false
        }
    }
}
