import Foundation

final class StoreObservers {
    private var yieldsToObservers: [UUID: () -> Void] = [:]

    func stream<Value: Sendable>(_ read: @escaping () -> Value) -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream.makeStream(of: Value.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        yieldsToObservers[id] = { continuation.yield(read()) }
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.remove(id) }
        }
        continuation.yield(read())
        return stream
    }

    func notify() {
        for yieldCurrentValue in yieldsToObservers.values {
            yieldCurrentValue()
        }
    }

    private func remove(_ id: UUID) {
        yieldsToObservers[id] = nil
    }
}
