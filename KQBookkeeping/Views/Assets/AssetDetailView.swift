import SwiftUI
import SwiftData

struct AssetDetailView: View {
    @Bindable var asset: Asset
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddTransaction = false
    @State private var showingEditPrice = false

    private var sortedTransactions: [Transaction] {
        asset.transactions.sorted { $0.date > $1.date }
    }

    private var isInvestment: Bool {
        asset.category == .usStock || asset.category == .jpFund
    }

    var body: some View {
        List {
            infoSection

            if isInvestment {
                holdingSection
            } else {
                balanceSummarySection
            }

            transactionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(asset.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView(asset: asset)
        }
        .sheet(isPresented: $showingEditPrice) {
            EditPriceView(asset: asset)
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        Section("基本信息") {
            LabeledContent("分类") {
                Label(asset.category.displayName, systemImage: asset.category.iconName)
            }
            LabeledContent("币种") {
                Text("\(asset.currency.flagEmoji) \(asset.currency.displayName)")
            }
            if let symbol = asset.symbol {
                LabeledContent("代码", value: symbol)
            }
            if let provider = asset.fundProvider {
                LabeledContent("基金公司", value: provider.displayName)
            }
            if let note = asset.note, !note.isEmpty {
                LabeledContent("备注", value: note)
            }
        }
    }

    // MARK: - Investment Holdings

    private var holdingSection: some View {
        Section("持仓概要") {
            LabeledContent("持有数量") {
                Text(asset.totalQuantity.formatted())
                    .monospacedDigit()
            }
            LabeledContent("平均成本") {
                Text(CurrencyFormatter.format(asset.averageCost, currency: asset.currency))
                    .monospacedDigit()
            }
            LabeledContent("总投入") {
                Text(CurrencyFormatter.format(asset.totalCost, currency: asset.currency))
                    .monospacedDigit()
            }

            Button {
                showingEditPrice = true
            } label: {
                HStack {
                    Text("当前价格")
                        .foregroundStyle(.primary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if let price = asset.currentPrice {
                            Text(CurrencyFormatter.format(price, currency: asset.currency))
                                .monospacedDigit()
                            if let update = asset.lastPriceUpdate {
                                Text("\(update, style: .relative)前更新")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        } else {
                            Text("点击设置")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            LabeledContent("市值") {
                Text(CurrencyFormatter.format(asset.marketValue, currency: asset.currency))
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }

            let gl = asset.totalGainLoss
            LabeledContent("盈亏") {
                HStack(spacing: 4) {
                    Text(CurrencyFormatter.format(gl, currency: asset.currency, showSign: true))
                    Text(CurrencyFormatter.formatPercent(asset.totalGainLossPercent))
                }
                .monospacedDigit()
                .fontWeight(.medium)
                .foregroundStyle(gl >= 0 ? .red : .green)
            }
        }
    }

    // MARK: - Bank / Cash Balance

    private var balanceSummarySection: some View {
        Section("余额概要") {
            LabeledContent("当前余额") {
                Text(CurrencyFormatter.format(asset.currentBalance, currency: asset.currency))
                    .monospacedDigit()
                    .fontWeight(.semibold)
            }
            LabeledContent("交易笔数") {
                Text("\(asset.transactions.count)")
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        Section("交易记录（\(asset.transactions.count)）") {
            if sortedTransactions.isEmpty {
                Text("暂无交易记录")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedTransactions) { tx in
                    TransactionRowView(transaction: tx, currency: asset.currency, isInvestment: isInvestment)
                }
                .onDelete(perform: deleteTransactions)
            }
        }
    }

    private func deleteTransactions(at offsets: IndexSet) {
        for index in offsets {
            let tx = sortedTransactions[index]
            modelContext.delete(tx)
        }
    }
}

// MARK: - Edit Price Sheet

struct EditPriceView: View {
    @Bindable var asset: Asset
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var priceText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("当前价格") {
                    TextField("价格（\(asset.currency.symbol)）", text: $priceText)
                        .keyboardType(.decimalPad)

                    if let currentPrice = asset.currentPrice {
                        LabeledContent("原价格") {
                            Text(CurrencyFormatter.format(currentPrice, currency: asset.currency))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("修改价格")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(Decimal(string: priceText) == nil)
                }
            }
            .onAppear {
                if let price = asset.currentPrice {
                    priceText = "\(price)"
                }
            }
        }
    }

    private func save() {
        guard let price = Decimal(string: priceText) else { return }
        asset.currentPrice = price
        asset.lastPriceUpdate = Date()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let alreadyHasSnapshot = asset.priceSnapshots.contains {
            calendar.isDate($0.date, inSameDayAs: today)
        }
        if !alreadyHasSnapshot {
            let snapshot = AssetPriceSnapshot(asset: asset, price: price, date: today)
            modelContext.insert(snapshot)
        }

        dismiss()
    }
}

// MARK: - Transaction Row

struct TransactionRowView: View {
    let transaction: Transaction
    let currency: Currency
    let isInvestment: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(transaction.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if isInvestment {
                    Text("\(transaction.quantity.formatted()) 份")
                        .font(.body.monospacedDigit())
                    Text("@ \(CurrencyFormatter.format(transaction.price, currency: currency))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(CurrencyFormatter.format(transaction.amount, currency: currency))
                    .font(.body.monospacedDigit())
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 2)
    }
}
