import SwiftUI

struct SettingsView: View {
    @State private var defaultCurrency: Currency = .cny

    var body: some View {
        NavigationStack {
            Form {
                Section("显示设置") {
                    Picker("默认币种", selection: $defaultCurrency) {
                        ForEach(Currency.allCases) { currency in
                            Text("\(currency.flagEmoji) \(currency.displayName)")
                                .tag(currency)
                        }
                    }
                }

                Section("数据管理") {
                    Button {
                        // Phase 5: 实现导出功能
                    } label: {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        // Phase 5: 实现导入功能
                    } label: {
                        Label("导入数据", systemImage: "square.and.arrow.down")
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: "1.0.0")
                    LabeledContent("开发者", value: "KQ")
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
}
