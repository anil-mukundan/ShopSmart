import SwiftUI

struct AddItemToListView: View {
    @Environment(AppDataStore.self) private var dataStore

    let shoppingList: ShoppingListModel
    let currentStore: StoreModel

    var body: some View {
        CreateItemView(
            currentStoreName: currentStore.name,
            currentStoreID: currentStore.id
        ) { newItem in
            let entry = ShoppingListEntryModel(
                listID: shoppingList.id,
                itemID: newItem.id,
                itemName: newItem.name
            )
            dataStore.addEntry(entry)
            dataStore.incrementFrequency(storeID: currentStore.id, itemID: newItem.id)
        }
    }
}

#Preview {
    let store = AppDataStore.preview
    let list = ShoppingListModel(id: "l1", storeID: "s1", storeName: "Whole Foods")
    store.shoppingLists = [list]
    return AddItemToListView(
        shoppingList: list,
        currentStore: StoreModel(id: "s1", name: "Whole Foods", itemIDs: ["i1"])
    )
    .environment(store)
}
