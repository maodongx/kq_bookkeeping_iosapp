import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("总览", systemImage: "chart.pie")
                }

            AssetListView()
                .tabItem {
                    Label("资产", systemImage: "building.columns")
                }

            ChartsView()
                .tabItem {
                    Label("分析", systemImage: "chart.xyaxis.line")
                }

            SpendingPlaceholderView()
                .tabItem {
                    Label("记账", systemImage: "yensign.circle")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Asset.self, Transaction.self], inMemory: true)
}
