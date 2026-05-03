import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var defaultCurrency: Currency = .cny
    @State private var showingExportShare = false
    @State private var showingImportPicker = false
    @State private var showingImportModeAlert = false
    @State private var importFileURL: URL?
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var exportFileURL: URL?

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
                        exportData()
                    } label: {
                        Label("导出数据", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("导入数据", systemImage: "square.and.arrow.down")
                    }
                }

                Section("关于") {
                    LabeledContent("版本", value: "1.0.0")
                    LabeledContent("数据格式版本", value: DataIOService.currentVersion)
                }
            }
            .navigationTitle("设置")
            .sheet(isPresented: $showingExportShare) {
                if let url = exportFileURL {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportFile(result)
            }
            .alert("导入数据", isPresented: $showingImportModeAlert) {
                Button("合并（跳过已有）") { performImport(mode: .merge) }
                Button("覆盖（清空后导入）", role: .destructive) { performImport(mode: .replace) }
                Button("取消", role: .cancel) { }
            } message: {
                Text("请选择导入方式。合并会跳过已存在的资产，覆盖会先清空所有数据再导入。")
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("确定") { }
            }
        }
    }

    private func exportData() {
        do {
            let data = try DataIOService.exportData(modelContext: modelContext)

            let fileName = "KQBookkeeping_\(formatDate(Date())).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)

            exportFileURL = tempURL
            showingExportShare = true
        } catch {
            alertMessage = "导出失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func handleImportFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFileURL = url
            showingImportModeAlert = true
        case .failure(let error):
            alertMessage = "文件选择失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func performImport(mode: DataIOService.ImportMode) {
        guard let url = importFileURL else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let data = try Data(contentsOf: url)
            try DataIOService.importData(data, modelContext: modelContext, mode: mode)
            alertMessage = "导入成功！"
            showingAlert = true
        } catch {
            alertMessage = "导入失败: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f.string(from: date)
    }
}

// MARK: - Share Sheet (UIKit bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [Asset.self], inMemory: true)
}
