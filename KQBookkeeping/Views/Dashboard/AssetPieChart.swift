import SwiftUI
import Charts

struct AssetPieChart: View {
    let assets: [Asset]
    let displayCurrency: Currency

    private var chartData: [(category: String, value: Double)] {
        let grouped = Dictionary(grouping: assets) { $0.category }
        return AssetCategory.allCases.compactMap { category in
            guard let items = grouped[category] else { return nil }
            let total = items
                .filter { $0.currency == displayCurrency }
                .reduce(Decimal.zero) { $0 + $1.marketValue }
            let doubleValue = NSDecimalNumber(decimal: total).doubleValue
            guard doubleValue > 0 else { return nil }
            return (category: category.displayName, value: doubleValue)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("资产分布")
                .font(.headline)

            if chartData.isEmpty {
                Text("暂无\(displayCurrency.displayName)资产数据")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart(chartData, id: \.category) { item in
                    SectorMark(
                        angle: .value("金额", item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("分类", item.category))
                    .cornerRadius(4)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
