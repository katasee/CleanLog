import Foundation

nonisolated enum TimerState: Sendable, Equatable {
    case idle
    case running(since: Date)
    case paused
    case finished
}

extension WorkDay {
    nonisolated var timerState: TimerState {
        if let open = sessions.last(where: { $0.end == nil }) {
            return .running(since: open.start)
        }
        if sessions.isEmpty {
            return .idle
        }
        return isTimerFinished ? .finished : .paused
    }

    nonisolated var hasRecordedTime: Bool {
        !sessions.isEmpty || manualDuration != nil
    }

    nonisolated func workedDuration(now: Date) -> Duration {
        manualDuration ?? sessions.reduce(.zero) { $0 + $1.duration(now: now) }
    }

    nonisolated func startingTimer(at now: Date, today: DayKey) throws(WorkDayError) -> WorkDay {
        try requireToday(today)
        if case .running = timerState { throw .timerState }
        var copy = self
        copy.sessions.append(
            WorkSession(
                id: UUID(),
                start: now,
                end: nil
            )
        )
        copy.isTimerFinished = false
        return copy
    }

    nonisolated func pausingTimer(at now: Date, today: DayKey) throws(WorkDayError) -> WorkDay {
        try requireToday(today)
        guard case .running = timerState else { throw .timerState }
        return closingOpenSession(at: now)
    }

    nonisolated func finishingTimer(at now: Date, today: DayKey) throws(WorkDayError) -> WorkDay {
        try requireToday(today)
        switch timerState {
        case .running, .paused:
            var copy = closingOpenSession(at: now)
            copy.isTimerFinished = true
            return copy
        case .idle, .finished:
            throw .timerState
        }
    }

    nonisolated func settingManualDuration(_ duration: Duration?) -> WorkDay {
        var copy = self
        copy.manualDuration = duration
        return copy
    }

    private nonisolated func requireToday(_ today: DayKey) throws(WorkDayError) {
        guard day == today else { throw .notToday }
    }

    private nonisolated func closingOpenSession(at now: Date) -> WorkDay {
        var copy = self
        if let index = copy.sessions.lastIndex(where: { $0.end == nil }) {
            copy.sessions[index].end = now
        }
        return copy
    }
}
