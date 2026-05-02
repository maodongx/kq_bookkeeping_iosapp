import SwiftUI
import SwiftData

struct AddAssetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: AssetCategory = .usStock
    @State private var currency: Currency = .usd
    @State private var symbol = ""
    @State private var fundProvider: FundProvider = .mufg
    @State private var note = ""

    // For bank/cash: initial balance
    @State private var initialBalanceText = ""

    private var isInvestment: Bool {
        category == .usStock || category == .jpFund
    }

    private var isValid: Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        if isInvestment && symbol.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        if !isInvestment {
            guard let balance = Decimal(string: initialBalanceText), balance >= 0 else {
                return initialBalanceText.isEmpty
            }
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                categorySection
                basicInfoSection

                if isInvestment {
                    symbolSection
                } else {
                    balanceSection
                }

                noteSection
            }
            .navigationTitle("添加资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") { save() }
                        .disabled(!isValid)
                }
            }
            .onChange(of: category) { _, newValue in
                switch newValue {
                case .usStock:
                    currency = .usd
                case .jpFund:
                    currency = .jpy
                default:
                    break
                }
            }
        }
    }

    private var categorySection: some View {
        Section("资产类型") {
            Picker("分类", selection: $category) {
                ForEach(AssetCategory.allCases) { cat in
                    Label(cat.displayName, systemImage: cat.iconName)
                        .tag(cat)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var basicInfoSection: some View {
        Section("基本信息") {
            TextField("名称", text: $name)

            Picker("币种", selection: $currency) {
                ForEach(Currency.allCases) { cur in
                    Text("\(cur.flagEmoji) \(cur.displayName)").tag(cur)
                }
            }
        }
    }

    private var symbolSection: some View {
        Section(category == .usStock ? "股票代码" : "基金信息") {
            if category == .jpFund {
                Picker("基金公司", selection: $fundProvider) {
                    ForEach(FundProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
            }

            TextField(
                category == .usStock ? "代码（如 AAPL）" : "基金代码",
                text: $symbol
            )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
        }
    }

    private var balanceSection: some View {
        Section("初始余额") {
            TextField("金额（可选）", text: $initialBalanceText)
                .keyboardType(.decimalPad)
        }
    }

    private var noteSection: some View {
        Section("备注") {
            TextField("备注（可选）", text: $note, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedSymbol = symbol.trimmingCharacters(in: .whitespaces)

        let asset = Asset(
            name: trimmedName,
            category: category,
            currency: currency,
            symbol: trimmedSymbol.isEmpty ? nil : trimmedSymbol,
            fundProvider: category == .jpFund ? fundProvider : nil,
            note: note.isEmpty ? nil : note
        )
        modelContext.insert(asset)

        if !isInvestment, let balance = Decimal(string: initialBalanceText), balance > 0 {
            let tx = Transaction(
                asset: asset,
                type: .deposit,
                quantity: balance,
                price: 1,
                amount: balance,
                date: Date()
            )
            modelContext.insert(tx)
        }

        dismiss()
    }
}

#Preview {
    AddAssetView()
        .modelContainer(for: [Asset.self, Transaction.self], inMemory: true)
}
