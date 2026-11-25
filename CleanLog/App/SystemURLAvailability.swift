import UIKit

final class SystemURLAvailability: URLAvailability {
    func canOpen(_ url: URL) -> Bool {
        UIApplication.shared.canOpenURL(url)
    }
}
