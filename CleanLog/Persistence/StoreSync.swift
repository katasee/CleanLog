import os

protocol StoreRepublishing: AnyObject {
    func republish()
}

final class StoreSync {
    private let merger: StoreDuplicateMerger
    private let stores: [any StoreRepublishing]
    private let remoteChanges: () -> AsyncStream<Void>
    private let logger = Logger(subsystem: "CleanLog", category: "StoreSync")

    init(
        merger: StoreDuplicateMerger,
        stores: [any StoreRepublishing],
        remoteChanges: @escaping () -> AsyncStream<Void> = StoreRemoteChanges.signals
    ) {
        self.merger = merger
        self.stores = stores
        self.remoteChanges = remoteChanges
    }

    func run() async {
        let changes = remoteChanges()
        mergeAndRepublish()
        for await _ in changes {
            logger.debug("The store changed remotely")
            mergeAndRepublish()
        }
    }

    private func mergeAndRepublish() {
        do {
            _ = try merger.mergeDuplicates()
        } catch {
            logger.error("Could not merge duplicates: \(error)")
        }
        for store in stores {
            store.republish()
        }
    }
}
