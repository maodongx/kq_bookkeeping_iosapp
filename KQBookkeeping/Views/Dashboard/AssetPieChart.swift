import SwiftUI
import Charts

struct AssetPieChart: View {
    let assets: [Asset]
    let displayCurrency: Currency
    let refreshManager: PriceRefreshManager

    private var categoryData: [(label: String, value: Double)] {
        let grouped = Dictionary(grouping: assets) { $0.category }
        return AssetCategory.allCases.compactMap { category in
            guard let items = grouped[category] else { return nil }
            let total = items.reduce(Decimal.zero) { sum, asset in
                sum + refreshManager.convert(asset.marketValue, from: asset.currency, to: displayCurrency)
            }
            let doubleValue = NSDecimalNumber(decimal: total).doubleValue
            guard doubleValue > 0 else { return nil }
            return (label: category.displayName, value: doubleValue)
        }
    }

    private var currencyData: [(label: String, value: Double)] {
        Currency.allCases.compactMap { currency in
            let total = assets
                .filter { $0.currency == currency }
                .reduce(Decimal.zero) { sum, asset in
                    sum + refreshManager.convert(asset.marketValue, from: asset.currency, to: displayCurrency)
                }
            let doubleValue = NSDecimalNumber(decimal: total).doubleValue
            guard doubleValue > 0 else { return nil }
            return (label: "\(currency.flagEmoji) \(currency.displayName)", value: doubleValue)
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            pieSection(title: "资产分类", data: categoryData)
            pieSection(title: "币种分布", data: currencyData)
        }
    }

    private func pieSection(title: String, data: [(label: String, value: Double)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            if data.isEmpty {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                HStack(alignment: .center, spacing: 16) {
                    Chart(data, id: \.label) { item in
                        SectorMark(
                            angle: .value("金额", item.value),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("分类", item.label))
                        .cornerRadius(4)
                    }
                    .chartLegend(.hidden)
                    .frame(width: 140, height: 140)

                    legendView(data: data)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func legendView(data: [(label: String, value: Double)]) -> some View {
        let total = data.reduce(0) { $0 + $1.value }
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(data, id: \.label) { item in
                HStack(spacing: 6) {
                    Text(item.label)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    let pct = total > 0 ? item.value / total * 100 : 0
                    Text(String(format: "%.0f%%", pct))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
