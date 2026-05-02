import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID
    var asset: Asset?
    var typeRaw: String
    var quantity: Decimal
    var price: Decimal
    var amount: Decimal
    var date: Date
    var note: String?

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .buy }
        set { typeRaw = newValue.rawValue }
    }

    init(
        asset: Asset? = nil,
        type: TransactionType,
        quantity: Decimal,
        price: Decimal,
        amount: Decimal,
        date: Date,
        note: String? = nil
    ) {
        self.id = UUID()
        self.asset = asset
        self.typeRaw = type.rawValue
        self.quantity = quantity
        self.price = price
        self.amount = amount
        self.date = date
        self.note = note
    }
}
