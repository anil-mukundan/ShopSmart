import SwiftUI
import SwiftData

/// Thin wrapper around CreateItemView that also adds the new item
/// to the given shopping list as an entry.
struct AddItemToListView: View {
    @Environment(\.modelContext) private var modelContext

    let shoppingList: ShoppingList
    let currentStore: Store

    var body: some View {
        CreateItemView(
            currentStoreName: currentStore.name,
            currentStoreID: currentStore.id
        ) { newItem in
            let entry = ShoppingListEntry(item: newItem)
            modelContext.insert(entry)
            shoppingList.entries.append(entry)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Store.self, Item.self, ShoppingList.self, ShoppingListEntry.self,
        configurations: config
    )
    let ctx = container.mainContext
    let store = Store(name: "Whole Foods")
    ctx.insert(store)
    let list = ShoppingList(store: store)
    ctx.insert(list)

    return AddItemToListView(shoppingList: list, currentStore: store)
        .modelContainer(container)
}
