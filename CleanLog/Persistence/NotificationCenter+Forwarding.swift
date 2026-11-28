import Foundation

nonisolated extension NotificationCenter {
    func forwarded<Element: Sendable>(
        _ name: Notification.Name,
        bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded,
        transform: @escaping @Sendable (Notification) -> Element?
    ) -> AsyncStream<Element> {
        let (stream, continuation) = AsyncStream.makeStream(of: Element.self, bufferingPolicy: bufferingPolicy)
        let forwarding = Task {
            for await notification in notifications(named: name) {
                if let element = transform(notification) {
                    continuation.yield(element)
                }
            }
            continuation.finish()
        }
        continuation.onTermination = { _ in
            forwarding.cancel()
        }
        return stream
    }
}
