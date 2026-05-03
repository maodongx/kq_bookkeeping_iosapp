import Foundation

struct PriceResult {
    let price: Decimal
    let change: Decimal?
    let date: Date
    let name: String?
}

protocol PriceServiceProtocol: Sendable {
    func fetchUSStockPrice(symbol: String) async throws -> PriceResult
    func fetchMUFGFundPrice(fundCode: String) async throws -> PriceResult
    func fetchYahooJPFundPrice(code: String) async throws -> PriceResult
}

protocol ExchangeRateServiceProtocol: Sendable {
    func fetchRates(base: Currency) async throws -> [Currency: Decimal]
}

enum PriceServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case parseError(String)
    case noData
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .networkError(let error): return "网络错误: \(error.localizedDescription)"
        case .parseError(let detail): return "数据解析错误: \(detail)"
        case .noData: return "未获取到数据"
        case .apiError(let msg): return "API错误: \(msg)"
        }
    }
}
