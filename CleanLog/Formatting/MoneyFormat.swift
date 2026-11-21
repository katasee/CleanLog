import Foundation

nonisolated enum MoneyFormat {
    private static let noBreakSpace: Character = "\u{00A0}"

    static func string(_ money: Money, locale: Locale = .current) -> String {
        let isWhole = money.grosze % 100 == 0
        let amount = Decimal(money.grosze) / 100
        let number = amount.formatted(
            .number
                .precision(.fractionLength(isWhole ? 0 : 2))
                .locale(locale)
        )
        let unbreakable = String(number.map { $0.isWhitespace ? noBreakSpace : $0 })
        return "\(unbreakable)\(noBreakSpace)zł"
    }
}
