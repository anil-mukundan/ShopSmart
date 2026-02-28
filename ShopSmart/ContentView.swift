import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ShopTab(selectedTab: $selectedTab)
                .tabItem {
                    Label("Shop", systemImage: "basket.fill")
                }
                .tag(0)
            ListsTab()
                .tabItem {
                    Label("Lists", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(1)
            ItemsTab()
                .tabItem {
                    Label("Items", systemImage: "tag.fill")
                }
                .tag(2)
            StoresTab()
                .tabItem {
                    Label("Stores", systemImage: "storefront.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Store.self, Item.self, ShoppingList.self, ShoppingListEntry.self],
            inMemory: true
        )
}
