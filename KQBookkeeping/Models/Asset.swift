import Foundation
import SwiftData

@Model
final class Asset {
    var id: UUID
    var name: String
    var categoryRaw: String
    var currencyRaw: String
    var symbol: String?
    var fundProviderRaw: String?
    var note: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Transaction.asset)
    var transactions: [Transaction] = []

    @Relationship(deleteRule: .cascade, inverse: \AssetPriceSnapshot.asset)
    var priceSnapshots: [AssetPriceSnapshot] = []

    var currentPrice: Decimal?
    var lastPriceUpdate: Date?

    var category: AssetCategory {
        get { AssetCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var currency: Currency {
        get { Currency(rawValue: currencyRaw) ?? .cny }
        set { currencyRaw = newValue.rawValue }
    }

    var fundProvider: FundProvider? {
        get { fundProviderRaw.flatMap { FundProvider(rawValue: $0) } }
        set { fundProviderRaw = newValue?.rawValue }
    }

    init(
        name: String,
        category: AssetCategory,
        currency: Currency,
        symbol: String? = nil,
        fundProvider: FundProvider? = nil,
        note: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.currencyRaw = currency.rawValue
        self.symbol = symbol
        self.fundProviderRaw = fundProvider?.rawValue
        self.note = note
        self.createdAt = Date()
    }

    var totalQuantity: Decimal {
        transactions.reduce(Decimal.zero) { total, tx in
            switch tx.type {
            case .buy, .deposit:
                return total + tx.quantity
            case .sell, .withdraw:
                return total - tx.quantity
            case .adjustment:
                return total + tx.quantity
            }
        }
    }

    var totalCost: Decimal {
        transactions.reduce(Decimal.zero) { total, tx in
            switch tx.type {
            case .buy:
                return total + tx.amount
            case .sell:
                return total - tx.amount
            default:
                return total
            }
        }
    }

    var averageCost: Decimal {
        let qty = totalQuantity
        guard qty > 0 else { return 0 }
        return totalCost / qty
    }

    var marketValue: Decimal {
        switch category {
        case .usStock, .jpFund:
            guard let price = currentPrice else { return totalCost }
            return totalQuantity * price
        case .bankDeposit, .cash, .other:
            return currentBalance
        }
    }

    var currentBalance: Decimal {
        transactions.reduce(Decimal.zero) { total, tx in
            switch tx.type {
            case .buy, .deposit:
                return total + tx.amount
            case .sell, .withdraw:
                return total - tx.amount
            case .adjustment:
                return total + tx.amount
            }
        }
    }

    var totalGainLoss: Decimal {
        switch category {
        case .usStock, .jpFund:
            return marketValue - totalCost
        case .bankDeposit, .cash, .other:
            return 0
        }
    }

    var totalGainLossPercent: Decimal {
        guard totalCost > 0 else { return 0 }
        return (totalGainLoss / totalCost) * 100
    }
}
