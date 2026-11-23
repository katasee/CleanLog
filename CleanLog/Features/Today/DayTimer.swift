import Foundation

enum DayTimer: Equatable {
    case idle
    case running(status: String)
    case paused
    case finished(total: String, span: String?)
    case past(total: String, span: String?)
}

extension DayTimer {
    init?(
        _ workDay: WorkDay,
        kind: DayKind,
        now: Date,
        calendar: Calendar,
        locale: Locale
    ) {
        let total = DurationFormat.short(workDay.workedDuration(now: now))
        let span = workDay.timeSpan.flatMap { Self.text(of: $0, calendar: calendar, locale: locale) }
        switch (kind, workDay.timerState) {
        case (.future, _):
            return nil
        case (.past, _):
            self = .past(total: total, span: span)
        case (.today, .idle):
            self = .idle
        case (.today, .running):
            let since = workDay.sessions.first?.start ?? now
            let time = DayFormat.time(since, calendar: calendar, locale: locale)
            self = .running(status: String(localized: .todayTimerRunning(time), locale: locale))
        case (.today, .paused):
            self = .paused
        case (.today, .finished):
            self = .finished(total: total, span: span)
        }
    }

    private static func text(of span: WorkSpan, calendar: Calendar, locale: Locale) -> String? {
        guard let end = span.end else { return nil }
        let start = DayFormat.time(span.start, calendar: calendar, locale: locale)
        let finish = DayFormat.time(end, calendar: calendar, locale: locale)
        guard span.pauses > .zero else {
            return String(localized: .todayTimerSpan(start, finish), locale: locale)
        }
        let pause = DurationFormat.pause(span.pauses, locale: locale)
        return String(localized: .todayTimerSpanWithPause(start, finish, pause), locale: locale)
    }
}
