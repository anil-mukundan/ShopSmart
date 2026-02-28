import Foundation

struct StoreModel: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var websiteURL: String?
    var itemIDs: [String] = []
}

struct ItemModel: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var brand: String?
    var imageData: Data?
}

struct ShoppingListModel: Identifiable, Codable {
    var id: String = UUID().uuidString
    var storeID: String
    var storeName: String
    var date: Date = .now
}

struct ShoppingListEntryModel: Identifiable, Codable {
    var id: String = UUID().uuidString
    var listID: String
    var itemID: String
    var itemName: String
    var isInCart: Bool = false
    var count: Int = 1
    var notes: String?
}

struct FrequencyModel: Identifiable, Codable {
    var id: String = UUID().uuidString
    var storeID: String
    var itemID: String
    var count: Int = 1
    var sortOrder: Int = Int.max
}
