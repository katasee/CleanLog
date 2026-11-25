import Foundation

protocol URLAvailability: AnyObject {
    func canOpen(_ url: URL) -> Bool
}

#if DEBUG
    final class FakeURLAvailability: URLAvailability {
        private let isAvailable: Bool

        init(isAvailable: Bool = true) {
            self.isAvailable = isAvailable
        }

        func canOpen(_ url: URL) -> Bool {
            isAvailable
        }
    }
#endif
