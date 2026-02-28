import SwiftUI
import SwiftData

struct ShopTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Store.name) private var stores: [Store]
    @Query private var allFrequencies: [StoreItemFrequency]
    @Query private var allShoppingLists: [ShoppingList]

    @Binding var selectedTab: Int
    @State private var selectedStoreID: PersistentIdentifier?
    @State private var itemCounts: [PersistentIdentifier: Int] = [:]

    private var selectedStore: Store? {
        stores.first { $0.id == selectedStoreID }
    }

    private var existingListForSelectedStore: ShoppingList? {
        guard let store = selectedStore else { return nil }
        return allShoppingLists.first { $0.store?.id == store.id }
    }

    private var availableItems: [Item] {
        guard let store = selectedStore else { return [] }

        var freqMap: [PersistentIdentifier: Int] = [:]
        for freq in allFrequencies where freq.store?.id == store.id {
            if let itemID = freq.item?.id {
                freqMap[itemID, default: 0] += freq.count
            }
        }

        return store.items.sorted { a, b in
            let freqA = freqMap[a.id, default: 0]
            let freqB = freqMap[b.id, default: 0]
            if freqA != freqB { return freqA > freqB }
            return a.name < b.name
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Store") {
                    if stores.isEmpty {
                        Text("Add stores in the Stores tab first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Select Store", selection: $selectedStoreID) {
                            Text("Choose a store…").tag(Optional<PersistentIdentifier>(nil))
                            ForEach(stores) { store in
                                Text(store.name).tag(Optional(store.id))
                            }
                        }
                        .onChange(of: selectedStoreID) {
                            if let existingList = existingListForSelectedStore {
                                var counts: [PersistentIdentifier: Int] = [:]
                                for entry in existingList.entries where !entry.isInCart {
                                    if let itemID = entry.item?.id {
                                        counts[itemID] = entry.count
                                    }
                                }
                                itemCounts = counts
                            } else {
                                itemCounts = [:]
                            }
                        }
                    }
                }

                if let store = selectedStore {
                    Section("Items at \(store.name)") {
                        if availableItems.isEmpty {
                            Text("No items assigned to this store.\nAssign items in the Items tab.")
                                .foregroundStyle(.secondary)
                                .font(.callout)
                        } else {
                            ForEach(availableItems) { item in
                                ItemSelectionRow(
                                    item: item,
                                    count: itemCounts[item.id],
                                    onTap: { toggleItem(item) },
                                    onIncrement: { incrementCount(for: item) },
                                    onDecrement: { decrementCount(for: item) }
                                )
                            }
                        }
                    }

                    if !itemCounts.isEmpty {
                        Section {
                            Button(action: saveList) {
                                let count = itemCounts.count
                                let suffix = count == 1 ? "" : "s"
                                let verb = existingListForSelectedStore != nil ? "Update" : "Save"
                                let icon = existingListForSelectedStore != nil
                                    ? "arrow.triangle.2.circlepath"
                                    : "square.and.arrow.down"
                                Label("\(verb) List — \(count) item\(suffix)", systemImage: icon)
                                    .frame(maxWidth: .infinity)
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.appAccent)
                            .controlSize(.large)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        }
                    }
                }
            }
            .navigationTitle("Shop")
        }
    }

    private func toggleItem(_ item: Item) {
        if itemCounts[item.id] != nil {
            itemCounts.removeValue(forKey: item.id)
        } else {
            itemCounts[item.id] = 1
        }
    }

    private func incrementCount(for item: Item) {
        itemCounts[item.id, default: 1] += 1
    }

    private func decrementCount(for item: Item) {
        guard let current = itemCounts[item.id] else { return }
        if current <= 1 {
            itemCounts.removeValue(forKey: item.id)
        } else {
            itemCounts[item.id] = current - 1
        }
    }

    private func saveList() {
        guard let store = selectedStore else { return }
        let itemsToSave = availableItems.filter { itemCounts[$0.id] != nil }
        guard !itemsToSave.isEmpty else { return }

        if let existingList = existingListForSelectedStore {
            // Track which items were already in the list before this update
            let existingItemIDs = Set(existingList.entries.compactMap { $0.item?.id })
            let checkedItemIDs = Set(existingList.entries.filter(\.isInCart).compactMap { $0.item?.id })

            // Remove all unchecked entries — they'll be replaced by the new selection
            let uncheckedEntries = existingList.entries.filter { !$0.isInCart }
            for entry in uncheckedEntries {
                modelContext.delete(entry)
            }
            existingList.entries.removeAll { !$0.isInCart }

            // Add new entries for each selected item (skip ones already checked off)
            for item in itemsToSave {
                guard !checkedItemIDs.contains(item.id) else { continue }
                let entry = ShoppingListEntry(item: item)
                entry.count = itemCounts[item.id] ?? 1
                modelContext.insert(entry)
                existingList.entries.append(entry)

                // Only increment frequency for items that weren't in the list before
                if !existingItemIDs.contains(item.id) {
                    incrementFrequency(for: item, at: store)
                }
            }

            existingList.date = .now
        } else {
            let list = ShoppingList(store: store)
            modelContext.insert(list)
            for item in itemsToSave {
                let entry = ShoppingListEntry(item: item)
                entry.count = itemCounts[item.id] ?? 1
                modelContext.insert(entry)
                list.entries.append(entry)
                incrementFrequency(for: item, at: store)
            }
        }

        selectedStoreID = nil
        itemCounts = [:]
        selectedTab = 1
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

// MARK: - Item Selection Row

private struct ItemSelectionRow: View {
    let item: Item
    let count: Int?
    let onTap: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .foregroundStyle(.primary)
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let count = count {
                HStack(spacing: 6) {
                    Button { onDecrement() } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.secondary)
                    }
                    Text("\(count) count")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(minWidth: 52, alignment: .center)
                    Button { onIncrement() } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .buttonStyle(.borderless)
            }
            Image(systemName: count != nil ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(count != nil ? Color.accentColor : Color.secondary)
                .font(.title3)
                .animation(.easeInOut(duration: 0.15), value: count != nil)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

#Preview {
    ShopTab(selectedTab: .constant(0))
        .modelContainer(
            for: [Store.self, Item.self, ShoppingList.self, ShoppingListEntry.self],
            inMemory: true
        )
}
