import Foundation

nonisolated enum MoneyFormat {
    private static let minorUnitsPerZloty = 100
    static let currencySymbol = "zł"
    private static let noBreakSpace: Character = "\u{00A0}"

    static func string(_ money: Money, locale: Locale = .current) -> String {
        "\(amount(money, locale: locale))\(noBreakSpace)\(currencySymbol)"
    }

    static func amount(_ money: Money, locale: Locale = .current) -> String {
        let isWhole = money.minorUnits % minorUnitsPerZloty == 0
        let zloty = Decimal(money.minorUnits) / Decimal(minorUnitsPerZloty)
        let number = zloty.formatted(
            .number
                .precision(.fractionLength(isWhole ? 0 : 2))
                .locale(locale)
        )
        return String(number.map { $0.isWhitespace ? noBreakSpace : $0 })
    }
}
