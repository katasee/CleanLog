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
        switch (kind, workDay.timerState) {
        case (.future, _):
            return nil
        case (.past, _):
            self = .past(
                total: Self.total(of: workDay, now: now),
                span: Self.span(
                    of: workDay,
                    calendar: calendar,
                    locale: locale
                )
            )
        case (.today, .idle):
            self = .idle
        case (.today, .running):
            let time = DayFormat.time(
                workDay.sessions.first?.start ?? now,
                calendar: calendar,
                locale: locale
            )
            self = .running(status: String(localized: .todayTimerRunning(time), locale: locale))
        case (.today, .paused):
            self = .paused
        case (.today, .finished):
            self = .finished(
                total: Self.total(of: workDay, now: now),
                span: Self.span(
                    of: workDay,
                    calendar: calendar,
                    locale: locale
                )
            )
        }
    }

    private static func total(of workDay: WorkDay, now: Date) -> String {
        DurationFormat.short(workDay.workedDuration(now: now))
    }

    private static func span(of workDay: WorkDay, calendar: Calendar, locale: Locale) -> String? {
        guard let span = workDay.timeSpan, let end = span.end else { return nil }
        let start = DayFormat.time(
            span.start,
            calendar: calendar,
            locale: locale
        )
        let finish = DayFormat.time(
            end,
            calendar: calendar,
            locale: locale
        )
        guard span.pauses > .zero else {
            return String(localized: .todayTimerSpan(start, finish), locale: locale)
        }
        let pause = DurationFormat.pause(span.pauses, locale: locale)
        return String(localized: .todayTimerSpanWithPause(start, finish, pause), locale: locale)
    }
}
