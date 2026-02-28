import SwiftUI
import SwiftData

struct AddFromStoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allFrequencies: [StoreItemFrequency]

    let shoppingList: ShoppingList
    let store: Store

    @State private var selectedItemIDs: Set<PersistentIdentifier> = []

    /// Store items that aren't already in this list, sorted by frequency then name.
    private var candidateItems: [Item] {
        let existingIDs = Set(shoppingList.entries.compactMap { $0.item?.id })

        var freqMap: [PersistentIdentifier: Int] = [:]
        for freq in allFrequencies where freq.store?.id == store.id {
            if let itemID = freq.item?.id {
                freqMap[itemID, default: 0] += freq.count
            }
        }

        return store.items
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
                                    if let notes = item.notes, !notes.isEmpty {
                                        Text(notes)
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

    private func toggleItem(_ item: Item) {
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    private func save() {
        let selected = candidateItems.filter { selectedItemIDs.contains($0.id) }
        for item in selected {
            let entry = ShoppingListEntry(item: item)
            modelContext.insert(entry)
            shoppingList.entries.append(entry)
            incrementFrequency(for: item, at: store)
        }
        dismiss()
    }

    private func incrementFrequency(for item: Item, at store: Store) {
        if let existing = allFrequencies.first(where: {
            $0.store?.id == store.id && $0.item?.id == item.id
        }) {
            existing.count += 1
        } else {
            modelContext.insert(StoreItemFrequency(store: store, item: item))
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Store.self, Item.self, ShoppingList.self, ShoppingListEntry.self, StoreItemFrequency.self,
        configurations: config
    )
    let ctx = container.mainContext
    let store = Store(name: "Whole Foods")
    let item1 = Item(name: "Organic Milk")
    let item2 = Item(name: "Sourdough Bread")
    ctx.insert(store)
    ctx.insert(item1)
    ctx.insert(item2)
    store.items = [item1, item2]
    let list = ShoppingList(store: store)
    ctx.insert(list)

    return AddFromStoreView(shoppingList: list, store: store)
        .modelContainer(container)
}
