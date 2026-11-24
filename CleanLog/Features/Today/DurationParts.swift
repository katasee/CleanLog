import Foundation

struct DurationParts: Equatable {
    var hours: Int
    var minutes: Int
}

extension DurationParts {
    init(roundingDown duration: Duration) {
        let totalMinutes = Int(duration.components.seconds / 60)
        self.init(hours: totalMinutes / 60, minutes: totalMinutes % 60)
    }

    var duration: Duration {
        .seconds((hours * 60 + minutes) * 60)
    }
}
