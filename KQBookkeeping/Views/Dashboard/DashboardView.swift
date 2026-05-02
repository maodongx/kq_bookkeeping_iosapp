import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var assets: [Asset]
    @Environment(\.modelContext) private var modelContext
    @Environment(PriceRefreshManager.self) private var refreshManager
    @State private var displayCurrency: Currency = .cny

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NetWorthCard(
                        assets: assets,
                        displayCurrency: $displayCurrency,
                        refreshManager: refreshManager
                    )

                    if refreshManager.isRefreshing {
                        ProgressView("正在刷新价格...")
                            .font(.caption)
                    }

                    if let error = refreshManager.lastError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                    }

                    if !assets.isEmpty {
                        AssetPieChart(
                            assets: assets,
                            displayCurrency: displayCurrency,
                            refreshManager: refreshManager
                        )

                        AssetSummaryList(
                            assets: assets,
                            displayCurrency: displayCurrency,
                            refreshManager: refreshManager
                        )
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .refreshable {
                await refreshManager.refreshAll(modelContext: modelContext)
            }
            .navigationTitle("总览")
            .task {
                await refreshManager.refreshIfNeeded(modelContext: modelContext)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("暂无资产")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("前往「资产」页面添加您的第一笔资产")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

private struct AssetSummaryList: View {
    let assets: [Asset]
    let displayCurrency: Currency
    let refreshManager: PriceRefreshManager

    private var groupedAssets: [(AssetCategory, [Asset])] {
        let grouped = Dictionary(grouping: assets) { $0.category }
        return AssetCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("资产明细")
                .font(.headline)

            ForEach(groupedAssets, id: \.0) { category, items in
                VStack(alignment: .leading, spacing: 8) {
                    Label(category.displayName, systemImage: category.iconName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(items) { asset in
                        AssetSummaryRow(
                            asset: asset,
                            displayCurrency: displayCurrency,
                            refreshManager: refreshManager
                        )
                    }
                }
            }
        }
    }
}

private struct AssetSummaryRow: View {
    let asset: Asset
    let displayCurrency: Currency
    let refreshManager: PriceRefreshManager

    private var convertedValue: Decimal {
        refreshManager.convert(asset.marketValue, from: asset.currency, to: displayCurrency)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.body)
                if let symbol = asset.symbol {
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(CurrencyFormatter.format(convertedValue, currency: displayCurrency))
                    .font(.body.monospacedDigit())

                if asset.category == .usStock || asset.category == .jpFund {
                    let gainLoss = asset.totalGainLoss
                    Text(CurrencyFormatter.format(gainLoss, currency: asset.currency, showSign: true))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(gainLoss >= 0 ? .red : .green)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Asset.self, Transaction.self], inMemory: true)
        .environment(PriceRefreshManager())
}
