import SwiftData
import Foundation

@Model
final class ShoppingList {
    var date: Date
    var store: Store?

    @Relationship(deleteRule: .cascade)
    var entries: [ShoppingListEntry] = []

    var storeName: String {
        store?.name ?? "Unknown Store"
    }

    init(store: Store, date: Date = .now) {
        self.store = store
        self.date = date
    }
}
