import Foundation

nonisolated enum MoneyFormat {
    private static let minorUnitsPerZloty = 100
    private static let currencySymbol = "zł"
    private static let noBreakSpace: Character = "\u{00A0}"

    static func string(_ money: Money, locale: Locale = .current) -> String {
        let isWhole = money.minorUnits % minorUnitsPerZloty == 0
        let amount = Decimal(money.minorUnits) / Decimal(minorUnitsPerZloty)
        let number = amount.formatted(
            .number
                .precision(.fractionLength(isWhole ? 0 : 2))
                .locale(locale)
        )
        let unbreakable = String(number.map { $0.isWhitespace ? noBreakSpace : $0 })
        return "\(unbreakable)\(noBreakSpace)\(currencySymbol)"
    }
}
