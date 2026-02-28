import SwiftData
import Foundation

/// Persistent counter tracking how many times an item has been
/// added to a shopping list for a specific store.
/// Incremented when a list is saved; unaffected by list deletions.
@Model
final class StoreItemFrequency {
    var store: Store?
    var item: Item?
    var count: Int
    var sortOrder: Int = Int.max

    init(store: Store, item: Item, count: Int = 1, sortOrder: Int = Int.max) {
        self.store = store
        self.item = item
        self.count = count
        self.sortOrder = sortOrder
    }
}
