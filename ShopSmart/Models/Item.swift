import SwiftData
import Foundation

@Model
final class Item {
    var name: String
    var notes: String?
    var stores: [Store] = []

    init(name: String, notes: String? = nil) {
        self.name = name
        self.notes = notes
    }
}
