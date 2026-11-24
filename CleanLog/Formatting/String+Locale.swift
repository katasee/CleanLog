import Foundation

nonisolated extension String {
    init(localized resource: LocalizedStringResource, locale: Locale) {
        var resource = resource
        resource.locale = locale
        self.init(localized: resource)
    }
}
