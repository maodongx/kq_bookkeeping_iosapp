import SwiftUI

struct NetWorthCard: View {
    let assets: [Asset]
    @Binding var displayCurrency: Currency
    let refreshManager: PriceRefreshManager

    private var totalNetWorth: Decimal {
        refreshManager.totalNetWorth(assets: assets, in: displayCurrency)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("总资产净值")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.format(totalNetWorth, currency: displayCurrency))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()

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
