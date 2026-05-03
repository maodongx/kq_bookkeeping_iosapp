import SwiftUI

struct NetWorthCard: View {
    let assets: [Asset]
    @Binding var displayCurrency: Currency
    let refreshManager: PriceRefreshManager

    private var totalNetWorth: Decimal {
        refreshManager.totalNetWorth(assets: assets, in: displayCurrency)
    }

    private var currencyBreakdown: [(currency: Currency, value: Decimal)] {
        Currency.allCases.compactMap { currency in
            let total = assets
                .filter { $0.currency == currency }
                .reduce(Decimal.zero) { $0 + $1.marketValue }
            guard total > 0 else { return nil }
            return (currency: currency, value: total)
        }
    }

    private var totalGainLoss: Decimal {
        assets
            .filter { $0.category == .usStock || $0.category == .jpFund }
            .reduce(Decimal.zero) { total, asset in
                total + refreshManager.convert(asset.totalGainLoss, from: asset.currency, to: displayCurrency)
            }
    }

    var body: some View {
        VStack(spacing: 14) {
            Text("总资产净值")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.format(totalNetWorth, currency: displayCurrency))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()

            if !assets.isEmpty {
                gainLossRow
            }

            if currencyBreakdown.count > 1 {
                currencyBreakdownView
            }

            if let lastRefresh = refreshManager.lastRefreshDate {
                Text("更新于 \(lastRefresh, style: .relative)前")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            currencyPicker
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var gainLossRow: some View {
        HStack(spacing: 4) {
            Text("投资盈亏")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(CurrencyFormatter.format(totalGainLoss, currency: displayCurrency, showSign: true))
                .font(.caption.monospacedDigit())
                .fontWeight(.medium)
                .foregroundStyle(totalGainLoss >= 0 ? .red : .green)
        }
    }

    private var currencyBreakdownView: some View {
        HStack(spacing: 12) {
            ForEach(currencyBreakdown, id: \.currency) { item in
                VStack(spacing: 2) {
                    Text(item.currency.flagEmoji)
                        .font(.caption)
                    Text(CurrencyFormatter.format(item.value, currency: item.currency))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var currencyPicker: some View {
        HStack(spacing: 8) {
            ForEach(Currency.allCases) { currency in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayCurrency = currency
                    }
                } label: {
                    Text("\(currency.flagEmoji) \(currency.rawValue)")
                        .font(.caption)
                        .fontWeight(displayCurrency == currency ? .semibold : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            displayCurrency == currency
                                ? Color.accentColor.opacity(0.15)
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
