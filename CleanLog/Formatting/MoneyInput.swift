import Foundation

nonisolated enum MoneyInput {
    private static let minorUnitsPerZloty = 100
    private static let maxFractionDigits = 2
    private static let decimalSeparators: Set<Character> = [",", "."]

    static func parse(_ text: String) -> Money? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(
            maxSplits: 1,
            omittingEmptySubsequences: false,
            whereSeparator: decimalSeparators.contains
        )
        guard let wholeText = parts.first, isDigits(wholeText), let whole = Int(wholeText) else {
            return nil
        }
        guard let fraction = parts.count > 1 ? fractionMinorUnits(parts[1]) : 0 else {
            return nil
        }
        let (wholeMinorUnits, overflows) = whole.multipliedReportingOverflow(by: minorUnitsPerZloty)
        guard !overflows else {
            return nil
        }
        return Money(minorUnits: wholeMinorUnits + fraction)
    }

    static func string(_ money: Money, locale: Locale = .current) -> String {
        let whole = money.minorUnits / minorUnitsPerZloty
        let fraction = money.minorUnits % minorUnitsPerZloty
        guard fraction != 0 else {
            return String(whole)
        }
        let separator = locale.decimalSeparator ?? "."
        let paddedFraction = fraction < 10 ? "0\(fraction)" : String(fraction)
        return "\(whole)\(separator)\(paddedFraction)"
    }

    private static func fractionMinorUnits(_ text: Substring) -> Int? {
        guard isDigits(text), text.count <= maxFractionDigits, let value = Int(text) else {
            return nil
        }
        return text.count == 1 ? value * 10 : value
    }

    private static func isDigits(_ text: Substring) -> Bool {
        !text.isEmpty && text.allSatisfy { $0.isASCII && $0.isNumber }
    }
}
