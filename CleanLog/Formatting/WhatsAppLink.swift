import Foundation

nonisolated enum WhatsAppLink {
    static let probe = link("whatsapp://send")

    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    static func url(for text: String) -> URL {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: unreserved) else {
            preconditionFailure("A Swift string always percent-encodes")
        }
        return link("whatsapp://send?text=\(encoded)")
    }

    private static func link(_ string: String) -> URL {
        guard let url = URL(string: string) else {
            preconditionFailure("Every reserved character is encoded in \(string)")
        }
        return url
    }
}
