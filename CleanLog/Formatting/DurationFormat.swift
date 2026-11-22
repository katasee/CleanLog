import Foundation

nonisolated enum DurationFormat {
    private static let secondsPerMinute: Int64 = 60
    private static let secondsPerHour: Int64 = 3600

    static func clock(_ duration: Duration) -> String {
        let (hours, minutes, seconds) = parts(of: duration)
        return "\(hours):\(twoDigits(minutes)):\(twoDigits(seconds))"
    }

    static func short(_ duration: Duration) -> String {
        let (hours, minutes, _) = parts(of: duration)
        return "\(hours):\(twoDigits(minutes))"
    }

    static func pause(_ duration: Duration, locale: Locale) -> String {
        var style = Duration.UnitsFormatStyle(allowedUnits: [.hours, .minutes], width: .abbreviated)
        style.locale = locale
        return duration.formatted(style)
    }

    private static func parts(of duration: Duration) -> (hours: Int64, minutes: Int64, seconds: Int64) {
        let total = max(duration.components.seconds, 0)
        return (
            total / secondsPerHour,
            total % secondsPerHour / secondsPerMinute,
            total % secondsPerMinute
        )
    }

    private static func twoDigits(_ value: Int64) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
