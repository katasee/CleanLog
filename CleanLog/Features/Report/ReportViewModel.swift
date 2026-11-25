import Foundation
import Observation

@Observable @MainActor
final class ReportViewModel {
    private let month: MonthKey
    private let today: DayKey
    private let workDays: any WorkDayRepository
    private let pasteboard: any Pasteboard
    private let confirmationDuration: Duration
    private let locale: Locale
    private let isWhatsAppAvailable: Bool

    let title: String
    private(set) var subtitle = ""
    private(set) var text = ""
    private(set) var isCopied = false
    private(set) var copyCount = 0

    init(
        month: MonthKey,
        today: DayKey,
        workDays: any WorkDayRepository,
        urlAvailability: any URLAvailability,
        pasteboard: any Pasteboard,
        confirmationDuration: Duration = .seconds(2),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.month = month
        self.today = today
        self.workDays = workDays
        self.pasteboard = pasteboard
        self.confirmationDuration = confirmationDuration
        self.locale = locale
        isWhatsAppAvailable = urlAvailability.canOpen(WhatsAppLink.probe)
        title = Self.title(
            of: month,
            today: today,
            calendar: calendar,
            locale: locale
        )
        refresh(from: [])
    }

    var hasReport: Bool {
        !text.isEmpty
    }

    var sendAction: ReportSendAction {
        isWhatsAppAvailable ? .whatsApp(WhatsAppLink.url(for: text)) : .share(text)
    }

    func observe() async {
        for await days in workDays.days(in: month) {
            refresh(from: days)
        }
    }

    func copy() {
        pasteboard.copy(text)
        isCopied = true
        copyCount += 1
    }

    func holdConfirmation() async {
        guard isCopied else { return }
        do {
            try await Task.sleep(for: confirmationDuration)
        } catch {
            return
        }
        isCopied = false
    }

    private func refresh(from days: [WorkDay]) {
        text = ReportBuilder.report(for: month, days: days)
        subtitle = Self.subtitle(of: .calculate(days: days, today: today), locale: locale)
    }

    private static func title(
        of month: MonthKey,
        today: DayKey,
        calendar: Calendar,
        locale: Locale
    ) -> String {
        let monthText = DayFormat.monthInTitle(
            month,
            includesYear: month.year != today.year,
            calendar: calendar,
            locale: locale
        )
        return String(localized: .reportTitle(monthText), locale: locale)
    }

    private static func subtitle(of stats: MonthStats, locale: Locale) -> String {
        String(
            localized: .reportSubtitle(
                String(localized: .reportSubtitleDays(stats.workingDays), locale: locale),
                String(localized: .reportSubtitleApartments(stats.cleanedCount), locale: locale)
            ),
            locale: locale
        )
    }
}
