import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let asset: Asset

    @State private var transactionType: TransactionType = .buy
    @State private var quantityText = ""
    @State private var priceText = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""

    private var isInvestment: Bool {
        asset.category == .usStock || asset.category == .jpFund
    }

    private var availableTypes: [TransactionType] {
        TransactionType.availableTypes(for: asset.category)
    }

    private var computedAmount: Decimal? {
        guard isInvestment else { return Decimal(string: amountText) }
        guard let qty = Decimal(string: quantityText),
              let price = Decimal(string: priceText) else { return nil }
        return qty * price
    }

    private var isValid: Bool {
        if isInvestment {
            guard let qty = Decimal(string: quantityText), qty > 0,
                  let price = Decimal(string: priceText), price > 0 else { return false }
        } else {
            guard let amount = Decimal(string: amountText), amount > 0 else { return false }
        }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                typeSection
                if isInvestment {
                    investmentInputSection
                } else {
                    amountInputSection
                }
                dateSection
                noteSection
            }
            .navigationTitle("添加交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                transactionType = availableTypes.first ?? .buy
            }
        }
    }

    private var typeSection: some View {
        Section("交易类型") {
            Picker("类型", selection: $transactionType) {
                ForEach(availableTypes) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var investmentInputSection: some View {
        Section("交易信息") {
            TextField("数量（份数）", text: $quantityText)
                .keyboardType(.decimalPad)
            TextField("单价（\(asset.currency.symbol)）", text: $priceText)
                .keyboardType(.decimalPad)
            if let amount = computedAmount {
                LabeledContent("总金额") {
                    Text(CurrencyFormatter.format(amount, currency: asset.currency))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var amountInputSection: some View {
        Section("金额") {
            TextField("金额（\(asset.currency.symbol)）", text: $amountText)
                .keyboardType(.decimalPad)
        }
    }

    private var dateSection: some View {
        Section("日期") {
            DatePicker("交易日期", selection: $date, displayedComponents: .date)
        }
    }

    private var noteSection: some View {
        Section("备注") {
            TextField("备注（可选）", text: $note, axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private func save() {
        let quantity: Decimal
        let price: Decimal
        let amount: Decimal

        if isInvestment {
            quantity = Decimal(string: quantityText) ?? 0
            price = Decimal(string: priceText) ?? 0
            amount = quantity * price
        } else {
            amount = Decimal(string: amountText) ?? 0
            quantity = amount
            price = 1
        }

        let tx = Transaction(
            asset: asset,
            type: transactionType,
            quantity: quantity,
            price: price,
            amount: amount,
            date: date,
            note: note.isEmpty ? nil : note
        )
        modelContext.insert(tx)
        dismiss()
    }
}
