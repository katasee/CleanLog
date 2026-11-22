import Foundation
import SwiftData

typealias ApartmentRecord = SchemaV1.ApartmentRecord
typealias WorkDayRecord = SchemaV1.WorkDayRecord
typealias DayEntryRecord = SchemaV1.DayEntryRecord
typealias WorkSessionRecord = SchemaV1.WorkSessionRecord

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [ApartmentRecord.self, WorkDayRecord.self, DayEntryRecord.self, WorkSessionRecord.self]
    }

    @Model
    final class ApartmentRecord {
        var id = UUID()
        var name = ""
        var priceMinorUnits = 0
        var accessCode: String?
        var isReportedSeparately = false
        var createdAt = Date.distantPast

        init() {}
    }

    @Model
    final class WorkDayRecord {
        var id = UUID()
        var dayValue = 0
        var manualDurationSeconds: Int?
        var isTimerFinished = false
        var isTimeDropped = false
        @Relationship(deleteRule: .cascade, inverse: \DayEntryRecord.day)
        var entries: [DayEntryRecord]? = []
        @Relationship(deleteRule: .cascade, inverse: \WorkSessionRecord.day)
        var sessions: [WorkSessionRecord]? = []

        init() {}
    }

    @Model
    final class DayEntryRecord {
        var id = UUID()
        var position = 0
        var apartmentID = UUID()
        var name = ""
        var priceMinorUnits = 0
        var isReportedSeparately = false
        var isCleaned = false
        var cleanedAt: Date?
        var day: WorkDayRecord?

        init() {}
    }

    @Model
    final class WorkSessionRecord {
        var id = UUID()
        var position = 0
        var start = Date.distantPast
        var end: Date?
        var day: WorkDayRecord?

        init() {}
    }
}
