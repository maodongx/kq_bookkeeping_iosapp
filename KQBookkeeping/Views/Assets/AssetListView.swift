import SwiftUI
import SwiftData

struct AssetListView: View {
    @Query(sort: \Asset.createdAt, order: .reverse) private var assets: [Asset]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddAsset = false

    private var groupedAssets: [(AssetCategory, [Asset])] {
        let grouped = Dictionary(grouping: assets) { $0.category }
        return AssetCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if assets.isEmpty {
                    emptyStateView
                } else {
                    assetList
                }
            }
            .navigationTitle("资产")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddAsset = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAsset) {
                AddAssetView()
            }
        }
    }

    private var assetList: some View {
        List {
            ForEach(groupedAssets, id: \.0) { category, items in
                Section {
                    ForEach(items) { asset in
                        NavigationLink(value: asset) {
                            AssetRowView(asset: asset)
                        }
                    }
                    .onDelete { offsets in
                        deleteAssets(items: items, at: offsets)
                    }
                } header: {
                    Label(category.displayName, systemImage: category.iconName)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: Asset.self) { asset in
            AssetDetailView(asset: asset)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("暂无资产")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("添加资产") {
                showingAddAsset = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func deleteAssets(items: [Asset], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}

struct AssetRowView: View {
    let asset: Asset

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text(asset.currency.flagEmoji)
                        .font(.caption)
                    if let symbol = asset.symbol {
                        Text(symbol)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if asset.category == .usStock || asset.category == .jpFund {
                        Text("数量: \(asset.totalQuantity.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.format(asset.marketValue, currency: asset.currency))
                    .font(.body.monospacedDigit())
                    .fontWeight(.medium)

                if asset.category == .usStock || asset.category == .jpFund {
                    let gl = asset.totalGainLoss
                    Text(CurrencyFormatter.formatPercent(asset.totalGainLossPercent))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(gl >= 0 ? .red : .green)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AssetListView()
        .modelContainer(for: [Asset.self, Transaction.self], inMemory: true)
}
