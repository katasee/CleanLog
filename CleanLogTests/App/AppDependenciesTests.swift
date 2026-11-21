import Testing

@testable import CleanLog

struct AppDependenciesTests {
    private let today = DayKey(year: 2026, month: 11, day: 13)

    @Test
    func previewStartsWithNoApartments() async {
        var stream = AppDependencies.preview().apartments.apartments().makeAsyncIterator()
        #expect(await stream.next() == [])
    }

    @Test
    func previewStartsWithAnEmptyDay() async {
        var stream = AppDependencies.preview().workDays.day(today).makeAsyncIterator()
        let day = await stream.next()
        #expect(day?.day == today)
        #expect(day?.isBlank == true)
    }
}
