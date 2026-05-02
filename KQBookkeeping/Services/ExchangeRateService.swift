import Foundation

struct ExchangeRateService: ExchangeRateServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRates(base: Currency) async throws -> [Currency: Decimal] {
        let urlString = "https://open.er-api.com/v6/latest/\(base.rawValue)"
        guard let url = URL(string: urlString) else {
            throw PriceServiceError.invalidURL
        }

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await session.data(from: url)
        } catch {
            throw PriceServiceError.networkError(error)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rates = json["rates"] as? [String: Double] else {
            throw PriceServiceError.parseError("汇率 API 响应格式异常")
        }

        var result: [Currency: Decimal] = [:]
        for currency in Currency.allCases {
            if currency == base {
                result[currency] = 1
            } else if let rate = rates[currency.rawValue] {
                result[currency] = Decimal(rate)
            }
        }

        return result
    }
}
