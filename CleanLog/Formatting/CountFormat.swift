import Foundation

nonisolated enum CountFormat {
    static func string(_ count: Int, locale: Locale) -> String {
        count.formatted(.number.locale(locale))
    }
}
