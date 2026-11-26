import Foundation

nonisolated enum ApartmentName {
    static func matchKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .caseInsensitive, locale: nil)
    }
}
