import SwiftData
import Foundation

@Model
final class Store {
    var name: String
    var notes: String?
    var websiteURL: String? = nil

    @Relationship(inverse: \Item.stores)
    var items: [Item] = []

    @Relationship(deleteRule: .nullify, inverse: \ShoppingList.store)
    var shoppingLists: [ShoppingList] = []

    init(name: String, notes: String? = nil) {
        self.name = name
        self.notes = notes
    }
}
