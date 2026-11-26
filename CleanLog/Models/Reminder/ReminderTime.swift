import Foundation

nonisolated struct ReminderTime: Sendable, Hashable, Codable {
    private static let hours = 0...23
    private static let minutes = 0...59

    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        precondition(Self.hours.contains(hour), "Hour \(hour) is outside \(Self.hours)")
        precondition(Self.minutes.contains(minute), "Minute \(minute) is outside \(Self.minutes)")
        self.hour = hour
        self.minute = minute
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let hour = try container.decode(Int.self, forKey: .hour)
        let minute = try container.decode(Int.self, forKey: .minute)
        guard Self.hours.contains(hour), Self.minutes.contains(minute) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "No time of day at \(hour):\(minute)"
                )
            )
        }
        self.init(hour: hour, minute: minute)
    }

    init(_ date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else {
            preconditionFailure("No time components for \(date)")
        }
        self.init(hour: hour, minute: minute)
    }

    func date(on day: DayKey, calendar: Calendar) -> Date {
        let start = day.startDate(in: calendar)
        guard let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: start) else {
            preconditionFailure("Cannot place \(self) on \(day)")
        }
        return date
    }
}
