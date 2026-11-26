import Foundation

struct AppVersion: Equatable {
    private static let missing = "0"

    let number: String
    let build: String

    init(number: String, build: String) {
        self.number = number
        self.build = build
    }

    init(bundle: Bundle) {
        self.init(
            number: Self.value(of: "CFBundleShortVersionString", in: bundle),
            build: Self.value(of: "CFBundleVersion", in: bundle)
        )
    }

    private static func value(of key: String, in bundle: Bundle) -> String {
        bundle.object(forInfoDictionaryKey: key) as? String ?? missing
    }
}
