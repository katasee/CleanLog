struct ReportRoute: Identifiable {
    let month: MonthKey
    let today: DayKey

    var id: MonthKey { month }
}
