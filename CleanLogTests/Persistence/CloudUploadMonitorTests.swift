import CloudKit
import Testing

@testable import CleanLog

@Suite(.timeLimit(.minutes(1)))
struct CloudUploadMonitorTests {
    private let outcomes: AsyncStream<CloudUploadOutcome>
    private let outcome: AsyncStream<CloudUploadOutcome>.Continuation
    private let monitor: CloudUploadMonitor

    init() {
        (outcomes, outcome) = AsyncStream.makeStream(of: CloudUploadOutcome.self)
        monitor = CloudUploadMonitor(outcomes: { [outcomes] in outcomes })
    }

    private func run(through received: [CloudUploadOutcome]) async {
        received.forEach { outcome.yield($0) }
        outcome.finish()
        await monitor.run()
    }

    @Test
    func noErrorIsASuccess() {
        #expect(CloudUploadOutcome(error: nil) == .succeeded)
    }

    @Test
    func quotaExceededIsStorageFull() {
        #expect(CloudUploadOutcome(error: CKError(.quotaExceeded)) == .storageFull)
    }

    @Test
    func quotaInsideAPartialFailureIsStorageFull() {
        let recordID = CKRecord.ID(recordName: "apartment")
        let partialFailure = NSError(
            domain: CKErrorDomain,
            code: CKError.Code.partialFailure.rawValue,
            userInfo: [CKPartialErrorsByItemIDKey: [recordID: CKError(.quotaExceeded)]]
        )

        #expect(CloudUploadOutcome(error: partialFailure) == .storageFull)
    }

    @Test
    func otherErrorsAreFailures() {
        #expect(CloudUploadOutcome(error: CKError(.networkUnavailable)) == .failed)
    }

    @Test
    func storageFullSetsTheFlag() async {
        await run(through: [.storageFull])

        #expect(monitor.isStorageFull)
    }

    @Test
    func aSuccessClearsTheFlag() async {
        await run(through: [.storageFull, .succeeded])

        #expect(!monitor.isStorageFull)
    }

    @Test
    func anOtherFailureKeepsTheFlag() async {
        await run(through: [.storageFull, .failed])

        #expect(monitor.isStorageFull)
    }

    @Test
    func runEndsWhenItsTaskIsCancelled() async {
        let task = Task { await monitor.run() }

        task.cancel()

        await task.value
    }
}
