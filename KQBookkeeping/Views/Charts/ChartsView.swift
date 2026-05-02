import SwiftUI
import SwiftData

struct ChartsView: View {
    @Query private var assets: [Asset]

    var body: some View {
        NavigationStack {
            if assets.isEmpty {
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
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Phase 4: 折线图和柱状图将在此处实现
                        placeholderCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "总资产走势",
                            subtitle: "价格接入后将展示历史净值变化"
                        )
                        placeholderCard(
                            icon: "chart.bar",
                            title: "盈亏分析",
                            subtitle: "各资产盈亏对比"
                        )
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("分析")
    }

    private func placeholderCard(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    ChartsView()
        .modelContainer(for: [Asset.self], inMemory: true)
}
