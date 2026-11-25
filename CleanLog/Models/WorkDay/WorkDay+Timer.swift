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

    nonisolated func countedDuration(today: DayKey) -> Duration? {
        if let manualDuration { return manualDuration }
        switch timerState {
        case .idle, .running:
            return nil
        case .paused:
            return day < today ? closedSessionsDuration : nil
        case .finished:
            return closedSessionsDuration
        }
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
        if duration != nil {
            copy.isTimeDropped = false
        }
        return copy
    }

    nonisolated func droppingOverrunTimer(today: DayKey) -> WorkDay {
        guard day < today, hasOpenSession else { return self }
        var copy = self
        copy.sessions = []
        copy.isTimerFinished = false
        copy.isTimeDropped = true
        return copy
    }

    nonisolated var hasOpenSession: Bool {
        sessions.contains { $0.end == nil }
    }

    nonisolated var timeSpan: WorkSpan? {
        guard manualDuration == nil, let first = sessions.first, let last = sessions.last else { return nil }
        let pauses = zip(sessions, sessions.dropFirst()).reduce(Duration.zero) { total, neighbours in
            let (previous, next) = neighbours
            guard let previousEnd = previous.end else { return total }
            return total + .seconds(max(next.start.timeIntervalSince(previousEnd), 0))
        }
        return WorkSpan(
            start: first.start,
            end: last.end,
            pauses: pauses
        )
    }

    private nonisolated var closedSessionsDuration: Duration {
        sessions.compactMap { session in session.end.map(session.duration(now:)) }.reduce(.zero, +)
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
