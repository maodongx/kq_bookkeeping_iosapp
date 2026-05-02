import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var assets: [Asset]
    @State private var displayCurrency: Currency = .cny

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NetWorthCard(
                        assets: assets,
                        displayCurrency: $displayCurrency
                    )

                    if !assets.isEmpty {
                        AssetPieChart(assets: assets, displayCurrency: displayCurrency)

                        AssetSummaryList(assets: assets, displayCurrency: displayCurrency)
                    } else {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("总览")
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
                        AssetSummaryRow(asset: asset)
                    }
                }
            }
        }
    }
}

private struct AssetSummaryRow: View {
    let asset: Asset

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
                Text(CurrencyFormatter.format(asset.marketValue, currency: asset.currency))
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
}
