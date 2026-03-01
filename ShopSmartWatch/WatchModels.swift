import Foundation

struct WatchList: Identifiable {
    let id: String
    let storeName: String
    let date: Date
    var entries: [WatchEntry]

    var uncheckedCount: Int { entries.filter { !$0.isInCart }.count }
    var totalCount: Int { entries.count }

    init?(from dict: [String: Any]) {
        guard let id        = dict["id"]        as? String,
              let storeName = dict["storeName"] as? String else { return nil }
        self.id        = id
        self.storeName = storeName
        let ts   = dict["date"] as? TimeInterval ?? 0
        self.date    = Date(timeIntervalSince1970: ts)
        let raw  = dict["entries"] as? [[String: Any]] ?? []
        self.entries = raw.compactMap { WatchEntry(from: $0) }
    }
}

struct WatchEntry: Identifiable {
    let id: String
    let itemID: String
    let itemName: String
    let count: Int
    var isInCart: Bool
    let brand: String?
    let imageData: Data?
    let notes: String?

    var hasDetails: Bool { brand != nil || imageData != nil || notes != nil }

    init?(from dict: [String: Any]) {
        guard let id       = dict["id"]       as? String,
              let itemName = dict["itemName"] as? String else { return nil }
        self.id        = id
        self.itemID    = dict["itemID"]   as? String ?? ""
        self.itemName  = itemName
        self.count     = dict["count"]    as? Int  ?? 1
        self.isInCart  = dict["isInCart"] as? Bool ?? false
        self.brand     = dict["brand"]    as? String
        self.imageData = dict["imageData"] as? Data
        self.notes     = dict["notes"]    as? String
    }
}
