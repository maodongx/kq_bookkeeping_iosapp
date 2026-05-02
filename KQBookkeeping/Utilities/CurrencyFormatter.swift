import Foundation

struct CurrencyFormatter {
    static func format(_ value: Decimal, currency: Currency, showSign: Bool = false) -> String {
        let nsValue = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = currency == .jpy ? 0 : 2
        formatter.maximumFractionDigits = currency == .jpy ? 0 : 2

        let formatted = formatter.string(from: nsValue) ?? "0"
        let sign = showSign && value > 0 ? "+" : ""
        return "\(sign)\(currency.symbol)\(formatted)"
    }

    static func formatPercent(_ value: Decimal, showSign: Bool = true) -> String {
        let nsValue = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        let formatted = formatter.string(from: nsValue) ?? "0"
        let sign = showSign && value > 0 ? "+" : ""
        return "\(sign)\(formatted)%"
    }
}
