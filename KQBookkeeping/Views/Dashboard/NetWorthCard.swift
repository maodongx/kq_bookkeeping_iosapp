import SwiftUI

struct NetWorthCard: View {
    let assets: [Asset]
    @Binding var displayCurrency: Currency

    private var totalNetWorth: Decimal {
        // TODO: Phase 2 — convert all assets to displayCurrency using exchange rates
        // For now, sum assets in each currency separately and show the selected one
        assets
            .filter { $0.currency == displayCurrency }
            .reduce(Decimal.zero) { $0 + $1.marketValue }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("总资产净值")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.format(totalNetWorth, currency: displayCurrency))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()

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
