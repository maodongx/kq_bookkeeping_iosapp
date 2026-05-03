import Foundation

struct PriceService: PriceServiceProtocol {
    private static let browserUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
    private static let tokyoTZ = TimeZone(identifier: "Asia/Tokyo")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - US Stocks (Yahoo Finance)

    func fetchUSStockPrice(symbol: String) async throws -> PriceResult {
        let url = try buildURL("https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=1d&range=1d")
        let data = try await fetch(url: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chart = json["chart"] as? [String: Any],
              let results = chart["result"] as? [[String: Any]],
              let meta = results.first?["meta"] as? [String: Any],
              let price = meta["regularMarketPrice"] as? Double,
              let previousClose = meta["chartPreviousClose"] as? Double else {
            throw PriceServiceError.parseError("Yahoo Finance 响应格式异常")
        }

        return PriceResult(
            price: Decimal(price),
            change: Decimal(price) - Decimal(previousClose),
            date: Date(),
            name: meta["shortName"] as? String
        )
    }

    // MARK: - MUFG Funds (eMAXIS etc.)

    func fetchMUFGFundPrice(fundCode: String) async throws -> PriceResult {
        let url = try buildURL("https://www.am.mufg.jp/mukamapi/fund_details/?fund_cd=\(fundCode)")
        let data = try await fetch(url: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let datasets = json["datasets"] as? [String: Any],
              let basePrice = datasets["cfm_base_price"] as? Int else {
            throw PriceServiceError.parseError("MUFG 响应格式异常")
        }

        return PriceResult(
            price: Decimal(basePrice),
            change: (datasets["cfm_price_changes"] as? Int).map { Decimal($0) },
            date: parseTokyoDate(datasets["cfm_base_date"] as? String) ?? Date(),
            name: datasets["cff_fund_name"] as? String
        )
    }

    // MARK: - Yahoo Finance JP Funds (Rakuten etc.)

    func fetchYahooJPFundPrice(code: String) async throws -> PriceResult {
        let jwt = try await fetchYahooJPToken(code: code)
        return try await fetchYahooJPHistory(code: code, jwt: jwt)
    }

    private func fetchYahooJPToken(code: String) async throws -> String {
        let url = try buildURL("https://finance.yahoo.co.jp/quote/\(code)")
        let data = try await fetch(url: url, headers: ["User-Agent": Self.browserUA])
        guard let html = String(data: data, encoding: .utf8) else {
            throw PriceServiceError.parseError("无法解码 Yahoo Finance JP 页面")
        }

        let patterns = [
            ("\"jwtToken\"\\s*:\\s*\"([^\"]+)\"", 1),
            ("eyJhbGciOiJIUzI1NiJ9\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+", 0)
        ]
        for (pattern, group) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: group), in: html) {
                return String(html[range])
            }
        }

        throw PriceServiceError.parseError("无法从 Yahoo Finance JP 提取 JWT Token")
    }

    private func fetchYahooJPHistory(code: String, jwt: String) async throws -> PriceResult {
        let today = tokyoDateString(from: Date())
        let url = try buildURL("https://finance.yahoo.co.jp/bff-pc/v1/main/fund/chart/history/\(code)?fromDate=&size=2&timeFrame=daily&toDate=\(today)")
        let data = try await fetch(url: url, headers: [
            "jwt-token": jwt,
            "User-Agent": Self.browserUA
        ])

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let histories = json["priceHistories"] as? [[String: Any]],
              let latest = histories.first,
              let closePrice = latest["closePrice"] as? Double else {
            throw PriceServiceError.parseError("Yahoo Finance JP 基金数据格式异常")
        }

        var change: Decimal?
        if histories.count >= 2, let prevClose = histories[1]["closePrice"] as? Double {
            change = Decimal(closePrice) - Decimal(prevClose)
        }

        return PriceResult(
            price: Decimal(closePrice),
            change: change,
            date: parseTokyoDate(latest["baseDate"] as? String) ?? Date(),
            name: nil
        )
    }

    // MARK: - Helpers

    private func buildURL(_ string: String) throws -> URL {
        guard let url = URL(string: string) else { throw PriceServiceError.invalidURL }
        return url
    }

    private func fetch(url: URL, headers: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        do {
            let (data, _) = try await session.data(for: request)
            return data
        } catch {
            throw PriceServiceError.networkError(error)
        }
    }

    private func tokyoDateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        f.timeZone = Self.tokyoTZ
        return f.string(from: date)
    }

    private func parseTokyoDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let f = DateFormatter()
        f.timeZone = Self.tokyoTZ
        for format in ["yyyyMMdd", "yyyy-MM-dd"] {
            f.dateFormat = format
            if let date = f.date(from: string) { return date }
        }
        return nil
    }
}
