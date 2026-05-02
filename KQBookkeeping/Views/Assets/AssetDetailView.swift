import SwiftUI
import SwiftData

struct AssetDetailView: View {
    @Bindable var asset: Asset
    @State private var showingAddTransaction = false

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
    }

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
            if let price = asset.currentPrice {
                LabeledContent("当前价格") {
                    Text(CurrencyFormatter.format(price, currency: asset.currency))
                        .monospacedDigit()
                }
            }
            LabeledContent("市值") {
                Text(CurrencyFormatter.format(asset.marketValue, currency: asset.currency))
                    .monospacedDigit()
                    .fontWeight(.medium)
            }
            LabeledContent("盈亏") {
                let gl = asset.totalGainLoss
                HStack(spacing: 4) {
                    Text(CurrencyFormatter.format(gl, currency: asset.currency, showSign: true))
                    Text(CurrencyFormatter.formatPercent(asset.totalGainLossPercent))
                }
                .monospacedDigit()
                .foregroundStyle(gl >= 0 ? .red : .green)
            }
        }
    }

    private var transactionsSection: some View {
        Section("交易记录（\(asset.transactions.count)）") {
            if sortedTransactions.isEmpty {
                Text("暂无交易记录")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedTransactions) { tx in
                    TransactionRowView(transaction: tx, currency: asset.currency, isInvestment: isInvestment)
                }
            }
        }
    }
}

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
