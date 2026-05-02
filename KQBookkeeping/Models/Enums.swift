import Foundation

enum AssetCategory: String, Codable, CaseIterable, Identifiable {
    case usStock = "usStock"
    case jpFund = "jpFund"
    case bankDeposit = "bankDeposit"
    case cash = "cash"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .usStock: return "美股"
        case .jpFund: return "日本基金"
        case .bankDeposit: return "银行存款"
        case .cash: return "现金"
        case .other: return "其他"
        }
    }

    var iconName: String {
        switch self {
        case .usStock: return "chart.line.uptrend.xyaxis"
        case .jpFund: return "yensign.circle"
        case .bankDeposit: return "building.columns"
        case .cash: return "banknote"
        case .other: return "square.grid.2x2"
        }
    }
}

enum Currency: String, Codable, CaseIterable, Identifiable {
    case usd = "USD"
    case jpy = "JPY"
    case cny = "CNY"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .usd: return "美元"
        case .jpy: return "日元"
        case .cny: return "人民币"
        }
    }

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .jpy: return "¥"
        case .cny: return "¥"
        }
    }

    var flagEmoji: String {
        switch self {
        case .usd: return "🇺🇸"
        case .jpy: return "🇯🇵"
        case .cny: return "🇨🇳"
        }
    }
}

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case buy = "buy"
    case sell = "sell"
    case deposit = "deposit"
    case withdraw = "withdraw"
    case adjustment = "adjustment"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .buy: return "买入"
        case .sell: return "卖出"
        case .deposit: return "存入"
        case .withdraw: return "取出"
        case .adjustment: return "调整"
        }
    }

    static func availableTypes(for category: AssetCategory) -> [TransactionType] {
        switch category {
        case .usStock, .jpFund:
            return [.buy, .sell]
        case .bankDeposit, .cash:
            return [.deposit, .withdraw, .adjustment]
        case .other:
            return TransactionType.allCases
        }
    }
}

enum FundProvider: String, Codable, CaseIterable, Identifiable {
    case mufg = "mufg"
    case rakuten = "rakuten"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mufg: return "三菱UFJ (eMAXIS等)"
        case .rakuten: return "乐天证券"
        case .other: return "其他"
        }
    }
}
