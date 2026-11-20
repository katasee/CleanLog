import Foundation

@testable import CleanLog

/// The user's real October 2026 report (her typos corrected) and the days that must produce it.
enum OctoberReport {
    static let expected = """
        1.10-(54,96,100,105,115,116,138)=7
        2.10-(54,64,96,105,115,138,6piw)=7+155
        3.10-(54,64,96,100,105,115,116)=7+155
        4.10-(54,64,96,100,105,115,116,138)=8+155

        5.10-(54,96,100,105,115,138,6piw)=7
        6.10-(54,96,105,115,116,138)=6
        7.10-(54,100,115,116)=4+155
        8.10-(54,64,96,100,105,115,116,138)=8+155
        9.10-(64,96,100,105,115,138)=6
        10.10-(54,64,96,115,116,138)=6+155
        11.10-(54,64,96,100,105,115,116,138)=8+155

        12.10-(96,100,115,138,133kol)=5
        13.10-(100,105,115,116)=4
        14.10-(96,116)=2
        15.10-(96,100,105,115,138)=5
        16.10-(54,64,105,133kol)=4+155
        17.10-(100,105,115,116,138)=5
        18.10-(54,64,96,100,105,115,138)=7+155

        19.10-(54,96,100,105,116,138)=6
        20.10-(54,100,105,115,116,138)=6+155
        21.10-(54,64,96,100,105,115,116,138)=8+155
        22.10-(64,100,105,115,116,138)=6
        23.10-(64,96,116,138)=4+155
        24.10-(54,105,115,116,138)=5
        25.10-(54,96,100,105,115,138)=6+155

        26.10-(64,115,138)=3+155
        27.10-(54,64,96,105,115,133kol)=6
        28.10-(54,96,100,115,116,138)=6
        29.10-(54,64,96,100,138)=5
        30.10-(96,115,116,133kol)=4+155
        31.10-(96,100,115)=3+155
        """

    /// The template in its order; `155` is reported separately.
    static let template: [Apartment] = ["54", "64", "96", "100", "105", "115", "116", "138", "6piw", "133kol", "155"]
        .enumerated()
        .map { index, name in Apartment.fixture(name, separate: name == "155", sortOrder: index) }

    /// One day per line of `expected`: the line's apartments ticked, in shuffled order, plus one
    /// unticked apartment — so the builder has to sort and filter.
    static var days: [WorkDay] {
        expected.split(separator: "\n").map { line in
            let dayNumber = Int(line.prefix { $0 != "." }) ?? 0
            let names = Set(cleanedNames(in: String(line)))
            let cleaned = template.filter { names.contains($0.name) }
            let spare = template.first { !names.contains($0.name) && !$0.isReportedSeparately }
            var day = WorkDay.empty(DayKey(year: 2026, month: 10, day: dayNumber))
                .planning((cleaned + [spare].compactMap(\.self)).shuffled())
            for index in day.entries.indices where names.contains(day.entries[index].name) {
                day.entries[index].isCleaned = true
                day.entries[index].cleanedAt = .warsaw(2026, 10, dayNumber, 12)
            }
            return day
        }
    }

    /// `"2.10-(54,64)=2+155"` → `["54", "64", "155"]`.
    private static func cleanedNames(in line: String) -> [String] {
        let inside = line.drop { $0 != "(" }.dropFirst().prefix { $0 != ")" }
        let separate = line.split(separator: "+").dropFirst().map(String.init)
        return inside.split(separator: ",").map(String.init) + separate
    }
}
