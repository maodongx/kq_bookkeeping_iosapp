import Foundation

struct PriceService: PriceServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - US Stocks (Yahoo Finance)

    func fetchUSStockPrice(symbol: String) async throws -> PriceResult {
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?interval=1d&range=1d"
        guard let url = URL(string: urlString) else {
            throw PriceServiceError.invalidURL
        }

        let (data, _) = try await performRequest(url: url)
        return try parseYahooResponse(data: data)
    }

    private func parseYahooResponse(data: Data) throws -> PriceResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chart = json["chart"] as? [String: Any],
              let results = chart["result"] as? [[String: Any]],
              let result = results.first,
              let meta = result["meta"] as? [String: Any],
              let regularMarketPrice = meta["regularMarketPrice"] as? Double,
              let previousClose = meta["chartPreviousClose"] as? Double else {
            throw PriceServiceError.parseError("Yahoo Finance 响应格式异常")
        }

        let price = Decimal(regularMarketPrice)
        let change = Decimal(regularMarketPrice) - Decimal(previousClose)
        let shortName = meta["shortName"] as? String

        return PriceResult(
            price: price,
            change: change,
            date: Date(),
            name: shortName
        )
    }

    // MARK: - MUFG Funds (eMAXIS etc.)

    func fetchMUFGFundPrice(fundCode: String) async throws -> PriceResult {
        let urlString = "https://www.am.mufg.jp/mukamapi/fund_details/?fund_cd=\(fundCode)"
        guard let url = URL(string: urlString) else {
            throw PriceServiceError.invalidURL
        }

        let (data, _) = try await performRequest(url: url)
        return try parseMUFGResponse(data: data)
    }

    private func parseMUFGResponse(data: Data) throws -> PriceResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let datasets = json["datasets"] as? [String: Any] else {
            throw PriceServiceError.parseError("MUFG 响应格式异常")
        }

        guard let basePrice = datasets["cfm_base_price"] as? Int else {
            throw PriceServiceError.parseError("无法获取基準価額")
        }

        let priceChange = datasets["cfm_price_changes"] as? Int
        let fundName = datasets["cff_fund_name"] as? String
        let baseDateStr = datasets["cfm_base_date"] as? String

        var date = Date()
        if let baseDateStr {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            if let parsed = formatter.date(from: baseDateStr) {
                date = parsed
            }
        }

        return PriceResult(
            price: Decimal(basePrice),
            change: priceChange.map { Decimal($0) },
            date: date,
            name: fundName
        )
    }

    // MARK: - Nikkei Funds (HTML scrape, best-effort)

    func fetchNikkeiFundPrice(fcode: String) async throws -> PriceResult {
        let urlString = "https://www.nikkei.com/nkd/fund/?fcode=\(fcode)"
        guard let url = URL(string: urlString) else {
            throw PriceServiceError.invalidURL
        }

        let (data, _) = try await performRequest(url: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw PriceServiceError.parseError("无法解码 Nikkei 页面")
        }

        return try parseNikkeiHTML(html: html)
    }

    private func parseNikkeiHTML(html: String) throws -> PriceResult {
        // Nikkei page displays: 基準価格(M/d)：XX,XXX円  前日比：±NNN
        let patterns = [
            "基準価格[^0-9]*?([0-9,]+)\\s*円",
            "基準価額[^0-9]*?([0-9,]+)\\s*円",
        ]

        var price: Decimal?
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let priceStr = html[range].replacingOccurrences(of: ",", with: "")
                if let priceInt = Int(priceStr) {
                    price = Decimal(priceInt)
                    break
                }
            }
        }

        guard let price else {
            throw PriceServiceError.parseError("无法从 Nikkei 页面提取基準価格")
        }

        // Try to extract 前日比 change
        var change: Decimal?
        let changePattern = "前日比[^0-9-]*([+-]?[0-9,]+)"
        if let regex = try? NSRegularExpression(pattern: changePattern, options: .dotMatchesLineSeparators),
           let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
           let range = Range(match.range(at: 1), in: html) {
            let changeStr = html[range].replacingOccurrences(of: ",", with: "")
            if let changeInt = Int(changeStr) {
                change = Decimal(changeInt)
            }
        }

        return PriceResult(
            price: price,
            change: change,
            date: Date(),
            name: nil
        )
    }

    // MARK: - Helpers

    private func performRequest(url: URL) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(from: url)
        } catch {
            throw PriceServiceError.networkError(error)
        }
    }
}
