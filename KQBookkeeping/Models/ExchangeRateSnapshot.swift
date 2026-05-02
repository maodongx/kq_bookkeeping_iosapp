import Foundation
import SwiftData

@Model
final class ExchangeRateSnapshot {
    var id: UUID
    var baseCurrencyRaw: String
    var targetCurrencyRaw: String
    var rate: Decimal
    var date: Date

    var baseCurrency: Currency {
        get { Currency(rawValue: baseCurrencyRaw) ?? .usd }
        set { baseCurrencyRaw = newValue.rawValue }
    }

    var targetCurrency: Currency {
        get { Currency(rawValue: targetCurrencyRaw) ?? .cny }
        set { targetCurrencyRaw = newValue.rawValue }
    }

    init(baseCurrency: Currency, targetCurrency: Currency, rate: Decimal, date: Date) {
        self.id = UUID()
        self.baseCurrencyRaw = baseCurrency.rawValue
        self.targetCurrencyRaw = targetCurrency.rawValue
        self.rate = rate
        self.date = date
    }
}
