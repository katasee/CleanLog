import Foundation

struct DayRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let accessCode: String?
    let isReportedSeparately: Bool
    let isCleaned: Bool
}

extension DayRow {
    init(_ entry: DayEntry, template: [Apartment]) {
        self.init(
            id: entry.id,
            name: entry.name,
            accessCode: template.first { $0.id == entry.apartmentID }?.accessCode,
            isReportedSeparately: entry.isReportedSeparately,
            isCleaned: entry.isCleaned
        )
    }
}
