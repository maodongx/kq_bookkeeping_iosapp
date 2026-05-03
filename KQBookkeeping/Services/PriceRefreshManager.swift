import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class PriceRefreshManager {
    var isRefreshing = false
    var lastRefreshDate: Date?
    var lastError: String?

    // Exchange rates keyed by base currency, e.g. rates[.usd][.cny] = 7.24
    var exchangeRates: [Currency: [Currency: Decimal]] = [:]

    private let priceService: PriceServiceProtocol
    private let exchangeRateService: ExchangeRateServiceProtocol
    private let autoRefreshInterval: TimeInterval = 30 * 60 // 30 minutes

    init(
        priceService: PriceServiceProtocol = PriceService(),
        exchangeRateService: ExchangeRateServiceProtocol = ExchangeRateService()
    ) {
        self.priceService = priceService
        self.exchangeRateService = exchangeRateService
    }

    var needsAutoRefresh: Bool {
        guard let last = lastRefreshDate else { return true }
        return Date().timeIntervalSince(last) > autoRefreshInterval
    }

    func refreshIfNeeded(modelContext: ModelContext) async {
        guard needsAutoRefresh else { return }
        await refreshAll(modelContext: modelContext)
    }

    func refreshAll(modelContext: ModelContext) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        lastError = nil

        do {
            try await refreshExchangeRates(modelContext: modelContext)
        } catch {
            lastError = error.localizedDescription
        }

        let descriptor = FetchDescriptor<Asset>()
        guard let assets = try? modelContext.fetch(descriptor) else {
            isRefreshing = false
            return
        }

        for asset in assets {
            do {
                try await refreshAssetPrice(asset: asset, modelContext: modelContext)
            } catch {
                // Individual asset failures don't block others
                print("价格刷新失败 [\(asset.name)]: \(error.localizedDescription)")
            }
        }

        lastRefreshDate = Date()
        isRefreshing = false
    }

    private func refreshAssetPrice(asset: Asset, modelContext: ModelContext) async throws {
        let result: PriceResult

        switch asset.category {
        case .usStock:
            guard let symbol = asset.symbol, !symbol.isEmpty else { return }
            result = try await priceService.fetchUSStockPrice(symbol: symbol)

        case .jpFund:
            guard let code = asset.symbol, !code.isEmpty else { return }
            switch asset.fundProvider {
            case .mufg:
                result = try await priceService.fetchMUFGFundPrice(fundCode: code)
            case .rakuten:
                result = try await priceService.fetchYahooJPFundPrice(code: code)
            case .other, nil:
                return
            }

        case .bankDeposit, .cash, .other:
            return
        }

        asset.currentPrice = result.price
        asset.lastPriceUpdate = Date()

        saveDailySnapshot(asset: asset, price: result.price, date: result.date, modelContext: modelContext)
    }

    private func saveDailySnapshot(asset: Asset, price: Decimal, date: Date, modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        let existingSnapshots = asset.priceSnapshots.filter {
            calendar.isDate($0.date, inSameDayAs: today)
        }
        guard existingSnapshots.isEmpty else { return }

        let snapshot = AssetPriceSnapshot(asset: asset, price: price, date: today)
        modelContext.insert(snapshot)
    }

    // MARK: - Exchange Rates

    private func refreshExchangeRates(modelContext: ModelContext) async throws {
        for base in Currency.allCases {
            let rates = try await exchangeRateService.fetchRates(base: base)
            exchangeRates[base] = rates

            for (target, rate) in rates where target != base {
                saveExchangeRateSnapshot(
                    base: base,
                    target: target,
                    rate: rate,
                    modelContext: modelContext
                )
            }
        }
    }

    private func saveExchangeRateSnapshot(base: Currency, target: Currency, rate: Decimal, modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let descriptor = FetchDescriptor<ExchangeRateSnapshot>(
            predicate: #Predicate {
                $0.baseCurrencyRaw == base.rawValue &&
                $0.targetCurrencyRaw == target.rawValue &&
                $0.date >= today
            }
        )
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let snapshot = ExchangeRateSnapshot(baseCurrency: base, targetCurrency: target, rate: rate, date: today)
        modelContext.insert(snapshot)
    }

    // MARK: - Currency Conversion

    func convert(_ amount: Decimal, from: Currency, to: Currency) -> Decimal {
        guard from != to else { return amount }
        guard let rates = exchangeRates[from], let rate = rates[to] else {
            return amount
        }
        return amount * rate
    }

    func totalNetWorth(assets: [Asset], in targetCurrency: Currency) -> Decimal {
        assets.reduce(Decimal.zero) { total, asset in
            let value = asset.marketValue
            return total + convert(value, from: asset.currency, to: targetCurrency)
        }
    }
}
