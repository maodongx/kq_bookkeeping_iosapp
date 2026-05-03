import SwiftUI
import Charts

enum TimeRange: String, CaseIterable, Identifiable {
    case oneWeek = "1周"
    case oneMonth = "1月"
    case threeMonths = "3月"
    case sixMonths = "6月"
    case oneYear = "1年"
    case all = "全部"

    var id: String { rawValue }

    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .oneWeek: return calendar.date(byAdding: .day, value: -7, to: Date())
        case .oneMonth: return calendar.date(byAdding: .month, value: -1, to: Date())
        case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: Date())
        case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: Date())
        case .oneYear: return calendar.date(byAdding: .year, value: -1, to: Date())
        case .all: return nil
        }
    }
}

struct NetWorthLineChart: View {
    let assets: [Asset]
    let displayCurrency: Currency
    let refreshManager: PriceRefreshManager

    @State private var selectedRange: TimeRange = .threeMonths

    private var chartData: [(date: Date, value: Double)] {
        let allSnapshots = assets.flatMap { asset in
            asset.priceSnapshots.map { snapshot in
                (asset: asset, snapshot: snapshot)
            }
        }

        let grouped = Dictionary(grouping: allSnapshots) { item in
            Calendar.current.startOfDay(for: item.snapshot.date)
        }

        let startDate = selectedRange.startDate ?? Date.distantPast

        return grouped
            .filter { $0.key >= startDate }
            .map { (date, items) in
                let totalValue = items.reduce(Decimal.zero) { sum, item in
                    let qty = item.asset.totalQuantity
                    let value = qty * item.snapshot.price
                    return sum + refreshManager.convert(value, from: item.asset.currency, to: displayCurrency)
                }

                // Add non-investment assets (bank/cash) as static value
                let staticValue = assets
                    .filter { $0.category != .usStock && $0.category != .jpFund }
                    .reduce(Decimal.zero) { sum, asset in
                        sum + refreshManager.convert(asset.currentBalance, from: asset.currency, to: displayCurrency)
                    }

                return (date: date, value: NSDecimalNumber(decimal: totalValue + staticValue).doubleValue)
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("总资产走势")
                .font(.headline)

            timeRangePicker

            if chartData.count < 2 {
                noDataView
            } else {
                Chart(chartData, id: \.date) { item in
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("净值", item.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.accentColor)

                    AreaMark(
                        x: .value("日期", item.date),
                        y: .value("净值", item.value)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatCompact(v))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        AxisGridLine()
                    }
                }
                .frame(height: 220)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var timeRangePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TimeRange.allCases) { range in
                    Button {
                        withAnimation { selectedRange = range }
                    } label: {
                        Text(range.rawValue)
                            .font(.caption)
                            .fontWeight(selectedRange == range ? .semibold : .regular)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                selectedRange == range
                                    ? Color.accentColor.opacity(0.15)
                                    : Color(.tertiarySystemBackground)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var noDataView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("价格数据不足，需要至少2天的快照")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }
}
