import Foundation

struct CopyOffer: Equatable {
    let count: Int
    let text: String
}

extension CopyOffer {
    init?(copying source: WorkDay, into workDay: WorkDay, template: [Apartment], locale: Locale) {
        guard workDay.entries.isEmpty else { return nil }
        let count = workDay.copyingPlan(from: source, template: template).entries.count
        guard count > 0 else { return nil }
        self.init(
            count: count,
            text: String(localized: .todayEmptyCopy(count), locale: locale)
        )
    }
}
