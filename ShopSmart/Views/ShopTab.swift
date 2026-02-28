import SwiftUI

struct ShopTab: View {
    @Environment(AppDataStore.self) private var dataStore

    @Binding var selectedTab: Int
    @State private var selectedStoreID: String?
    @State private var itemCounts: [String: Int] = [:]
    @State private var itemNotes: [String: String] = [:]
    @State private var noteEditTarget: NoteEditTarget?
    @State private var showHelp = false

    private var stores: [StoreModel] {
        dataStore.stores.sorted { $0.name < $1.name }
    }

    private var selectedStore: StoreModel? {
        stores.first { $0.id == selectedStoreID }
    }

    private var existingListForSelectedStore: ShoppingListModel? {
        guard let storeID = selectedStoreID else { return nil }
        return dataStore.shoppingLists.first { $0.storeID == storeID }
    }

    private var availableItems: [ItemModel] {
        guard let store = selectedStore else { return [] }

        var freqMap: [String: Int] = [:]
        for freq in dataStore.frequencies where freq.storeID == store.id {
            freqMap[freq.itemID, default: 0] += freq.count
        }

        return dataStore.items(for: store).sorted { a, b in
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
                            Text("Choose a store…").tag(Optional<String>(nil))
                            ForEach(stores) { store in
                                Text(store.name).tag(Optional(store.id))
                            }
                        }
                        .onChange(of: selectedStoreID) {
                            if let existingList = existingListForSelectedStore {
                                let existingEntries = dataStore.entries(forListID: existingList.id)
                                var counts: [String: Int] = [:]
                                var notes: [String: String] = [:]
                                for entry in existingEntries where !entry.isInCart {
                                    counts[entry.itemID] = entry.count
                                    if let n = entry.notes, !n.isEmpty { notes[entry.itemID] = n }
                                }
                                itemCounts = counts
                                itemNotes = notes
                            } else {
                                itemCounts = [:]
                                itemNotes = [:]
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
                                    note: itemNotes[item.id],
                                    onTap: { toggleItem(item) },
                                    onIncrement: { incrementCount(for: item) },
                                    onDecrement: { decrementCount(for: item) },
                                    onNote: { noteEditTarget = NoteEditTarget(id: item.id, itemName: item.name) }
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHelp = true } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showHelp) {
                OnboardingView(startPage: 4, helpMode: true)
            }
        }
        .sheet(item: $noteEditTarget) { target in
            NoteEditorSheet(
                itemName: target.itemName,
                note: Binding(
                    get: { itemNotes[target.id] ?? "" },
                    set: { newValue in
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty { itemNotes.removeValue(forKey: target.id) }
                        else { itemNotes[target.id] = newValue }
                    }
                )
            )
        }
    }

    private func toggleItem(_ item: ItemModel) {
        if itemCounts[item.id] != nil {
            itemCounts.removeValue(forKey: item.id)
        } else {
            itemCounts[item.id] = 1
        }
    }

    private func incrementCount(for item: ItemModel) {
        itemCounts[item.id, default: 1] += 1
    }

    private func decrementCount(for item: ItemModel) {
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
            let existingEntries = dataStore.entries(forListID: existingList.id)
            let existingItemIDs = Set(existingEntries.map(\.itemID))
            let checkedItemIDs = Set(existingEntries.filter(\.isInCart).map(\.itemID))

            // Remove unchecked entries
            for entry in existingEntries where !entry.isInCart {
                dataStore.deleteEntry(id: entry.id)
            }

            // Add new entries (skip already-checked items)
            for item in itemsToSave {
                guard !checkedItemIDs.contains(item.id) else { continue }
                let entry = ShoppingListEntryModel(
                    listID: existingList.id,
                    itemID: item.id,
                    itemName: item.name,
                    count: itemCounts[item.id] ?? 1,
                    notes: itemNotes[item.id]
                )
                dataStore.addEntry(entry)

                if !existingItemIDs.contains(item.id) {
                    dataStore.incrementFrequency(storeID: store.id, itemID: item.id)
                }
            }

            var updatedList = existingList
            updatedList.date = .now
            dataStore.updateShoppingList(updatedList)
        } else {
            let list = ShoppingListModel(storeID: store.id, storeName: store.name)
            dataStore.addShoppingList(list)
            for item in itemsToSave {
                let entry = ShoppingListEntryModel(
                    listID: list.id,
                    itemID: item.id,
                    itemName: item.name,
                    count: itemCounts[item.id] ?? 1,
                    notes: itemNotes[item.id]
                )
                dataStore.addEntry(entry)
                dataStore.incrementFrequency(storeID: store.id, itemID: item.id)
            }
        }

        selectedStoreID = nil
        itemCounts = [:]
        itemNotes = [:]
        selectedTab = 1
    }
}

// MARK: - Item Selection Row

private struct ItemSelectionRow: View {
    let item: ItemModel
    let count: Int?
    let note: String?
    let onTap: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onNote: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .foregroundStyle(.primary)
                if let brand = item.brand, !brand.isEmpty {
                    Text(brand)
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

                Button { onNote() } label: {
                    Image(systemName: note != nil ? "text.bubble.fill" : "text.bubble")
                        .foregroundStyle(note != nil ? Color.accentColor : .secondary)
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

// MARK: - Note Edit Target

private struct NoteEditTarget: Identifiable {
    let id: String      // itemID
    let itemName: String
}

// MARK: - Note Editor Sheet

private struct NoteEditorSheet: View {
    let itemName: String
    @Binding var note: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TextEditor(text: $note)
                .padding(.horizontal)
                .navigationTitle(itemName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Clear", role: .destructive) {
                            note = ""
                            dismiss()
                        }
                        .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ShopTab(selectedTab: .constant(0))
        .environment(AppDataStore.preview)
}
