import Foundation
import SwiftData

// MARK: - Export/Import Data Transfer Objects

struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let assets: [AssetDTO]
    let exchangeRateSnapshots: [ExchangeRateDTO]
}

struct AssetDTO: Codable {
    let id: String
    let name: String
    let category: String
    let currency: String
    let symbol: String?
    let fundProvider: String?
    let note: String?
    let currentPrice: String?
    let lastPriceUpdate: Date?
    let createdAt: Date
    let transactions: [TransactionDTO]
    let priceSnapshots: [PriceSnapshotDTO]
}

struct TransactionDTO: Codable {
    let id: String
    let type: String
    let quantity: String
    let price: String
    let amount: String
    let date: Date
    let note: String?
}

struct PriceSnapshotDTO: Codable {
    let id: String
    let price: String
    let date: Date
}

struct ExchangeRateDTO: Codable {
    let baseCurrency: String
    let targetCurrency: String
    let rate: String
    let date: Date
}

// MARK: - Service

enum DataIOError: LocalizedError {
    case exportFailed(String)
    case importFailed(String)
    case invalidVersion(String)

    var errorDescription: String? {
        switch self {
        case .exportFailed(let msg): return "导出失败: \(msg)"
        case .importFailed(let msg): return "导入失败: \(msg)"
        case .invalidVersion(let v): return "不支持的数据版本: \(v)"
        }
    }
}

struct DataIOService {
    static let currentVersion = "1.0"

    // MARK: - Export

    static func exportData(modelContext: ModelContext) throws -> Data {
        let assetDescriptor = FetchDescriptor<Asset>()
        let assets = try modelContext.fetch(assetDescriptor)

        let rateDescriptor = FetchDescriptor<ExchangeRateSnapshot>()
        let rates = try modelContext.fetch(rateDescriptor)

        let exportData = ExportData(
            version: currentVersion,
            exportDate: Date(),
            assets: assets.map { assetToDTO($0) },
            exchangeRateSnapshots: rates.map { rateToDTO($0) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(exportData)
    }

    private static func assetToDTO(_ asset: Asset) -> AssetDTO {
        AssetDTO(
            id: asset.id.uuidString,
            name: asset.name,
            category: asset.categoryRaw,
            currency: asset.currencyRaw,
            symbol: asset.symbol,
            fundProvider: asset.fundProviderRaw,
            note: asset.note,
            currentPrice: asset.currentPrice.map { "\($0)" },
            lastPriceUpdate: asset.lastPriceUpdate,
            createdAt: asset.createdAt,
            transactions: asset.transactions.map { txToDTO($0) },
            priceSnapshots: asset.priceSnapshots.map { snapshotToDTO($0) }
        )
    }

    private static func txToDTO(_ tx: Transaction) -> TransactionDTO {
        TransactionDTO(
            id: tx.id.uuidString,
            type: tx.typeRaw,
            quantity: "\(tx.quantity)",
            price: "\(tx.price)",
            amount: "\(tx.amount)",
            date: tx.date,
            note: tx.note
        )
    }

    private static func snapshotToDTO(_ snapshot: AssetPriceSnapshot) -> PriceSnapshotDTO {
        PriceSnapshotDTO(
            id: snapshot.id.uuidString,
            price: "\(snapshot.price)",
            date: snapshot.date
        )
    }

    private static func rateToDTO(_ rate: ExchangeRateSnapshot) -> ExchangeRateDTO {
        ExchangeRateDTO(
            baseCurrency: rate.baseCurrencyRaw,
            targetCurrency: rate.targetCurrencyRaw,
            rate: "\(rate.rate)",
            date: rate.date
        )
    }

    // MARK: - Import

    enum ImportMode {
        case merge
        case replace
    }

    static func importData(_ data: Data, modelContext: ModelContext, mode: ImportMode) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData: ExportData
        do {
            exportData = try decoder.decode(ExportData.self, from: data)
        } catch {
            throw DataIOError.importFailed("JSON 格式错误: \(error.localizedDescription)")
        }

        guard exportData.version == currentVersion else {
            throw DataIOError.invalidVersion(exportData.version)
        }

        if mode == .replace {
            try deleteAllData(modelContext: modelContext)
        }

        let existingAssetIDs = mode == .merge ? fetchExistingAssetIDs(modelContext: modelContext) : Set()

        for assetDTO in exportData.assets {
            guard let assetID = UUID(uuidString: assetDTO.id) else { continue }
            if mode == .merge && existingAssetIDs.contains(assetID) { continue }

            let asset = Asset(
                name: assetDTO.name,
                category: AssetCategory(rawValue: assetDTO.category) ?? .other,
                currency: Currency(rawValue: assetDTO.currency) ?? .cny,
                symbol: assetDTO.symbol,
                fundProvider: assetDTO.fundProvider.flatMap { FundProvider(rawValue: $0) },
                note: assetDTO.note
            )
            asset.id = assetID
            asset.createdAt = assetDTO.createdAt
            asset.currentPrice = assetDTO.currentPrice.flatMap { Decimal(string: $0) }
            asset.lastPriceUpdate = assetDTO.lastPriceUpdate
            modelContext.insert(asset)

            for txDTO in assetDTO.transactions {
                let tx = Transaction(
                    asset: asset,
                    type: TransactionType(rawValue: txDTO.type) ?? .buy,
                    quantity: Decimal(string: txDTO.quantity) ?? 0,
                    price: Decimal(string: txDTO.price) ?? 0,
                    amount: Decimal(string: txDTO.amount) ?? 0,
                    date: txDTO.date,
                    note: txDTO.note
                )
                if let id = UUID(uuidString: txDTO.id) { tx.id = id }
                modelContext.insert(tx)
            }

            for snapDTO in assetDTO.priceSnapshots {
                let snap = AssetPriceSnapshot(
                    asset: asset,
                    price: Decimal(string: snapDTO.price) ?? 0,
                    date: snapDTO.date
                )
                if let id = UUID(uuidString: snapDTO.id) { snap.id = id }
                modelContext.insert(snap)
            }
        }

        for rateDTO in exportData.exchangeRateSnapshots {
            guard let base = Currency(rawValue: rateDTO.baseCurrency),
                  let target = Currency(rawValue: rateDTO.targetCurrency),
                  let rate = Decimal(string: rateDTO.rate) else { continue }
            let snapshot = ExchangeRateSnapshot(
                baseCurrency: base, targetCurrency: target, rate: rate, date: rateDTO.date
            )
            modelContext.insert(snapshot)
        }
    }

    private static func deleteAllData(modelContext: ModelContext) throws {
        try modelContext.delete(model: Transaction.self)
        try modelContext.delete(model: AssetPriceSnapshot.self)
        try modelContext.delete(model: ExchangeRateSnapshot.self)
        try modelContext.delete(model: Asset.self)
    }

    private static func fetchExistingAssetIDs(modelContext: ModelContext) -> Set<UUID> {
        let descriptor = FetchDescriptor<Asset>()
        guard let assets = try? modelContext.fetch(descriptor) else { return Set() }
        return Set(assets.map(\.id))
    }
}
