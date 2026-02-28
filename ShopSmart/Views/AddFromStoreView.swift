import SwiftUI

struct AddFromStoreView: View {
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss

    let shoppingList: ShoppingListModel
    let store: StoreModel

    @State private var selectedItemIDs: Set<String> = []

    private var candidateItems: [ItemModel] {
        let existingIDs = Set(dataStore.entries(forListID: shoppingList.id).map(\.itemID))

        var freqMap: [String: Int] = [:]
        for freq in dataStore.frequencies where freq.storeID == store.id {
            freqMap[freq.itemID, default: 0] += freq.count
        }

        return dataStore.items(for: store)
            .filter { !existingIDs.contains($0.id) }
            .sorted { a, b in
                let freqA = freqMap[a.id, default: 0]
                let freqB = freqMap[b.id, default: 0]
                if freqA != freqB { return freqA > freqB }
                return a.name < b.name
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if candidateItems.isEmpty {
                    ContentUnavailableView(
                        "All Items Added",
                        systemImage: "checkmark.circle",
                        description: Text("Every item available at \(store.name) is already on this list.")
                    )
                } else {
                    List {
                        ForEach(candidateItems, id: \.id) { item in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let brand = item.brand, !brand.isEmpty {
                                        Text(brand)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedItemIDs.contains(item.id) ? Color.appAccent : Color.secondary)
                                    .font(.title3)
                                    .animation(.easeInOut(duration: 0.15), value: selectedItemIDs.contains(item.id))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                            .onTapGesture { toggleItem(item) }
                        }
                    }
                }
            }
            .navigationTitle("Add from \(store.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedItemIDs.count))") { save() }
                        .disabled(selectedItemIDs.isEmpty)
                }
            }
        }
    }

    private func toggleItem(_ item: ItemModel) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    private func save() {
        let selected = candidateItems.filter { selectedItemIDs.contains($0.id) }
        for item in selected {
            let entry = ShoppingListEntryModel(
                listID: shoppingList.id,
                itemID: item.id,
                itemName: item.name
            )
            dataStore.addEntry(entry)
            dataStore.incrementFrequency(storeID: store.id, itemID: item.id)
        }
        dismiss()
    }
}

#Preview {
    let store = AppDataStore.preview
    let list = ShoppingListModel(id: "l1", storeID: "s1", storeName: "Whole Foods")
    store.shoppingLists = [list]
    return AddFromStoreView(shoppingList: list, store: StoreModel(id: "s1", name: "Whole Foods", itemIDs: ["i1"]))
        .environment(store)
}
