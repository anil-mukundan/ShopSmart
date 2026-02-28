import SwiftData
import Foundation

@Model
final class ShoppingListEntry {
    var isInCart: Bool
    var item: Item?
    var count: Int = 1

    var itemName: String {
        item?.name ?? "Unknown Item"
    }

    init(item: Item, isInCart: Bool = false) {
        self.item = item
        self.isInCart = isInCart
    }
}
