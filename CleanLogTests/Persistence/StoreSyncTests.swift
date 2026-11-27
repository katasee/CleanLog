import Foundation
import SwiftData
import Testing

@testable import CleanLog

@Suite(.timeLimit(.minutes(1)))
struct StoreSyncTests {
    private let container = ModelContainer.inMemory()
    private let today = DayKey(year: 2026, month: 11, day: 13)
    private let signals: AsyncStream<Void>
    private let signal: AsyncStream<Void>.Continuation
    private let apartments: SwiftDataApartmentRepository
    private let workDays: SwiftDataWorkDayRepository

    init() {
        (signals, signal) = AsyncStream.makeStream(of: Void.self)
        apartments = SwiftDataApartmentRepository(container: container)
        workDays = SwiftDataWorkDayRepository(container: container)
    }

    private func startSync() -> Task<Void, Never> {
        let sync = StoreSync(
            merger: StoreDuplicateMerger(container: container),
            stores: [apartments, workDays],
            remoteChanges: { [signals] in signals }
        )
        return Task { await sync.run() }
    }

    private func importApartment(_ name: String) {
        let apartment = Apartment.fixture(name)
        container.mainContext.inserted(ApartmentRecord())
            .apply(Revision(value: apartment, changedAt: apartment.createdAt))
    }

    private func importDay(_ workDay: WorkDay) {
        container.mainContext.inserted(WorkDayRecord())
            .apply(Revision(value: workDay, changedAt: .warsaw(2026, 11, 13, 9)))
    }

    private func value<Element>(
        of stream: AsyncStream<Element>,
        where condition: (Element) -> Bool
    ) async -> Element? {
        for await element in stream where condition(element) {
            return element
        }
        return nil
    }

    @Test
    func mergesWhenItStarts() async {
        importApartment("100")
        importApartment("100")
        let stream = apartments.apartments()

        let task = startSync()
        defer { task.cancel() }

        let merged = await value(of: stream) { $0.count == 1 }
        #expect(merged?.map(\.name) == ["100"])
    }

    @Test
    func mergesAndRepublishesOnARemoteChange() async {
        importApartment("100")
        let task = startSync()
        defer { task.cancel() }
        let day = workDays.day(today)
        _ = await value(of: day) { _ in true }

        importApartment("100 ")
        importDay(.empty(today).planning([.fixture("101")]))
        signal.yield()

        let imported = await value(of: day) { !$0.entries.isEmpty }
        #expect(imported?.entries.map(\.name) == ["101"])
        let stored = await value(of: apartments.apartments()) { _ in true }
        #expect(stored?.count == 1)
    }

    @Test
    func republishesWithoutDuplicates() async {
        let task = startSync()
        defer { task.cancel() }
        let stream = apartments.apartments()
        _ = await value(of: stream) { _ in true }

        importApartment("101")
        signal.yield()

        let republished = await value(of: stream) { !$0.isEmpty }
        #expect(republished?.map(\.name) == ["101"])
    }

    @Test
    func runEndsWhenItsTaskIsCancelled() async {
        let task = startSync()

        task.cancel()

        await task.value
    }

    @Test
    func storageChoosesTheCloudDatabase() {
        let schema = Schema(versionedSchema: SchemaV1.self)

        let cloud = ModelStorage.iCloud(containerID: "iCloud.com.cleanlog").configuration(for: schema)
        let memory = ModelStorage.inMemory.configuration(for: schema)

        #expect(cloud.cloudKitContainerIdentifier == "iCloud.com.cleanlog")
        #expect(memory.cloudKitContainerIdentifier == nil)
        #expect(memory.isStoredInMemoryOnly)
    }
}
