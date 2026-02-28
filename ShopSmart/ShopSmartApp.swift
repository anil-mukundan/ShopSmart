import SwiftUI
import SwiftData

@main
struct ShopSmartApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.appAccent)
        }
        .modelContainer(for: [
            Store.self,
            Item.self,
            ShoppingList.self,
            ShoppingListEntry.self,
            StoreItemFrequency.self
        ])
    }
}
