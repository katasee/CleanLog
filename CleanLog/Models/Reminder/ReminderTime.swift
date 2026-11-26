import Foundation

nonisolated struct ReminderTime: Sendable, Hashable, Codable {
    let hour: Int
    let minute: Int

    init(hour: Int, minute: Int) {
        precondition((0...23).contains(hour), "Hour \(hour) is outside 0...23")
        precondition((0...59).contains(minute), "Minute \(minute) is outside 0...59")
        self.hour = hour
        self.minute = minute
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
