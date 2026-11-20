import Foundation
import Testing

@testable import CleanLog

struct WorkDayTimerTests {
    private let today = DayKey(year: 2026, month: 11, day: 13)

    private func at(_ hour: Int, _ minute: Int = 0) -> Date {
        .warsaw(2026, 11, 13, hour, minute)
    }

    @Test func movesThroughEveryState() throws {
        let idle = WorkDay.empty(today)
        #expect(idle.timerState == .idle)

        let running = try idle.startingTimer(at: at(7, 30), today: today)
        #expect(running.timerState == .running(since: at(7, 30)))

        let paused = try running.pausingTimer(at: at(10), today: today)
        #expect(paused.timerState == .paused)

        let resumed = try paused.startingTimer(at: at(10, 25), today: today)
        #expect(resumed.timerState == .running(since: at(10, 25)))

        let finished = try resumed.finishingTimer(at: at(13, 5), today: today)
        #expect(finished.timerState == .finished)

        let restarted = try finished.startingTimer(at: at(14), today: today)
        #expect(restarted.timerState == .running(since: at(14)))
        #expect(!restarted.isTimerFinished)
    }

    @Test func finishesFromPaused() throws {
        let paused = try WorkDay.empty(today)
            .startingTimer(at: at(8), today: today)
            .pausingTimer(at: at(9), today: today)
        #expect(try paused.finishingTimer(at: at(10), today: today).timerState == .finished)
    }

    @Test func refusesMovesThatMakeNoSense() throws {
        let idle = WorkDay.empty(today)
        let running = try idle.startingTimer(at: at(8), today: today)
        let paused = try running.pausingTimer(at: at(9), today: today)

        #expect(throws: WorkDayError.timerState) { try idle.pausingTimer(at: at(9), today: today) }
        #expect(throws: WorkDayError.timerState) { try paused.pausingTimer(at: at(10), today: today) }
        #expect(throws: WorkDayError.timerState) { try idle.finishingTimer(at: at(9), today: today) }
        #expect(throws: WorkDayError.timerState) { try running.startingTimer(at: at(9), today: today) }
    }

    @Test(arguments: [12, 14])
    func runsOnlyOnToday(day: Int) {
        let other = WorkDay.empty(DayKey(year: 2026, month: 11, day: day))
        #expect(throws: WorkDayError.notToday) { try other.startingTimer(at: at(9), today: today) }
    }

    @Test func sumsClosedSessions() throws {
        let day = try WorkDay.empty(today)
            .startingTimer(at: at(7, 30), today: today)
            .pausingTimer(at: at(10), today: today)
            .startingTimer(at: at(10, 25), today: today)
            .finishingTimer(at: at(13, 5), today: today)
        #expect(day.workedDuration(now: at(20)) == .seconds(5 * 3600 + 10 * 60))
    }

    @Test func countsAnOpenSessionUpToNow() throws {
        let day = try WorkDay.empty(today)
            .startingTimer(at: at(7, 30), today: today)
            .pausingTimer(at: at(10), today: today)
            .startingTimer(at: at(10, 25), today: today)
        #expect(day.workedDuration(now: at(11, 25)) == .seconds(3 * 3600 + 30 * 60))
    }

    @Test func keepsASessionPastMidnightOnTheDayItStarted() throws {
        let day = try WorkDay.empty(today)
            .startingTimer(at: at(23), today: today)
            .finishingTimer(at: .warsaw(2026, 11, 14, 1), today: today)
        #expect(day.workedDuration(now: .warsaw(2026, 11, 14, 9)) == .seconds(2 * 3600))
    }

    @Test func aManualDurationOverridesTheSessions() throws {
        let measured = try WorkDay.empty(today)
            .startingTimer(at: at(8), today: today)
            .finishingTimer(at: at(9), today: today)
        let corrected = measured.settingManualDuration(.seconds(4 * 3600))
        #expect(corrected.workedDuration(now: at(20)) == .seconds(4 * 3600))
        #expect(corrected.settingManualDuration(nil).workedDuration(now: at(20)) == .seconds(3600))
    }

    @Test func knowsWhetherTimeWasRecorded() throws {
        let empty = WorkDay.empty(today)
        #expect(!empty.hasRecordedTime)
        #expect(try empty.startingTimer(at: at(8), today: today).hasRecordedTime)
        #expect(empty.settingManualDuration(.seconds(60)).hasRecordedTime)
    }
}
