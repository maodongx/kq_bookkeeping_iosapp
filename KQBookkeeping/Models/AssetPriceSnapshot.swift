import Foundation
import SwiftData

@Model
final class AssetPriceSnapshot {
    var id: UUID
    var asset: Asset?
    var price: Decimal
    var date: Date

    init(asset: Asset? = nil, price: Decimal, date: Date) {
        self.id = UUID()
        self.asset = asset
        self.price = price
        self.date = date
    }
}
