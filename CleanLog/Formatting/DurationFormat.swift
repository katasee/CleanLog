import Foundation

/// Worked time with the same digits in every language: `4:12:35` for a running timer, `5:10` for a total.
nonisolated enum DurationFormat {
    static func clock(_ duration: Duration) -> String {
        let (hours, minutes, seconds) = parts(of: duration)
        return "\(hours):\(twoDigits(minutes)):\(twoDigits(seconds))"
    }

    static func short(_ duration: Duration) -> String {
        let (hours, minutes, _) = parts(of: duration)
        return "\(hours):\(twoDigits(minutes))"
    }

    private static func parts(of duration: Duration) -> (hours: Int64, minutes: Int64, seconds: Int64) {
        let total = max(duration.components.seconds, 0)
        return (total / 3600, total % 3600 / 60, total % 60)
    }

    private static func twoDigits(_ value: Int64) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}
