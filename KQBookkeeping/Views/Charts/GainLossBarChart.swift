import SwiftUI
import Charts

struct GainLossBarChart: View {
    let assets: [Asset]
    let displayCurrency: Currency
    let refreshManager: PriceRefreshManager

    private var chartData: [(name: String, gainLoss: Double, percent: Double)] {
        assets
            .filter { ($0.category == .usStock || $0.category == .jpFund) && $0.totalCost > 0 }
            .map { asset in
                let gl = refreshManager.convert(asset.totalGainLoss, from: asset.currency, to: displayCurrency)
                return (
                    name: asset.name,
                    gainLoss: NSDecimalNumber(decimal: gl).doubleValue,
                    percent: NSDecimalNumber(decimal: asset.totalGainLossPercent).doubleValue
                )
            }
            .sorted { abs($0.gainLoss) > abs($1.gainLoss) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("盈亏分析")
                .font(.headline)

            if chartData.isEmpty {
                noDataView
            } else {
                Chart(chartData, id: \.name) { item in
                    BarMark(
                        x: .value("盈亏", item.gainLoss),
                        y: .value("资产", item.name)
                    )
                    .foregroundStyle(item.gainLoss >= 0 ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                    .annotation(position: item.gainLoss >= 0 ? .trailing : .leading) {
                        Text(String(format: "%+.1f%%", item.percent))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatCompact(v))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .frame(height: max(CGFloat(chartData.count) * 44, 120))

                legendView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(chartData, id: \.name) { item in
                HStack {
                    Text(item.name)
                        .font(.caption)
                    Spacer()
                    Text(CurrencyFormatter.format(
                        Decimal(item.gainLoss),
                        currency: displayCurrency,
                        showSign: true
                    ))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(item.gainLoss >= 0 ? .red : .green)
                }
            }
        }
        .padding(.top, 4)
    }

    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("暂无投资资产盈亏数据")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private func formatCompact(_ value: Double) -> String {
        let abs = Swift.abs(value)
        let sign = value < 0 ? "-" : ""
        if abs >= 1_000_000 {
            return "\(sign)\(String(format: "%.1fM", abs / 1_000_000))"
        } else if abs >= 1_000 {
            return "\(sign)\(String(format: "%.0fK", abs / 1_000))"
        }
        return "\(sign)\(String(format: "%.0f", abs))"
    }
}
