import SwiftUI
import SwiftData

struct ChartsView: View {
    @Query private var assets: [Asset]
    @Environment(PriceRefreshManager.self) private var refreshManager
    @State private var displayCurrency: Currency = .cny

    var body: some View {
        NavigationStack {
            if assets.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        currencyPicker

                        NetWorthLineChart(
                            assets: assets,
                            displayCurrency: displayCurrency,
                            refreshManager: refreshManager
                        )

                        GainLossBarChart(
                            assets: assets,
                            displayCurrency: displayCurrency,
                            refreshManager: refreshManager
                        )
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("分析")
    }

    private var currencyPicker: some View {
        HStack(spacing: 8) {
            Text("显示币种")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            ForEach(Currency.allCases) { currency in
                Button {
                    withAnimation { displayCurrency = currency }
                } label: {
                    Text("\(currency.flagEmoji) \(currency.rawValue)")
                        .font(.caption)
                        .fontWeight(displayCurrency == currency ? .semibold : .regular)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            displayCurrency == currency
                                ? Color.accentColor.opacity(0.15)
                                : Color(.tertiarySystemBackground)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("暂无数据")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("添加资产并记录交易后，这里将展示分析图表")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    ChartsView()
        .modelContainer(for: [Asset.self], inMemory: true)
        .environment(PriceRefreshManager())
}
