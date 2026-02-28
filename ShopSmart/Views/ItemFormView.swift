import SwiftUI

struct ItemFormView: View {
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss

    var item: ItemModel?

    @State private var name = ""
    @State private var notes = ""
    @State private var selectedStoreIDs: Set<String> = []
    @State private var duplicateItem: ItemModel? = nil
    @State private var showDuplicateAlert = false
    @State private var pendingName: String = ""

    private var isEditing: Bool { item != nil }

    private var allStores: [StoreModel] {
        dataStore.stores.sorted { $0.name < $1.name }
    }

    private var allItems: [ItemModel] {
        dataStore.items.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Name") {
                    TextField("e.g. Organic Milk", text: $name)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    if allStores.isEmpty {
                        Text("Add stores in the Stores tab first.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(allStores, id: \.id) { store in
                            HStack {
                                Text(store.name)
                                Spacer()
                                if selectedStoreIDs.contains(store.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { toggleStore(store) }
                        }
                    }
                } header: {
                    Text("Available At")
                } footer: {
                    if !allStores.isEmpty && selectedStoreIDs.isEmpty {
                        Text("Select at least one store to save this item.")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  (!allStores.isEmpty && selectedStoreIDs.isEmpty))
                }
            }
        }
        .alert("Item Already Exists", isPresented: $showDuplicateAlert) {
            Button("Use Existing") { dismiss() }
            Button("Create Anyway", role: .destructive) { performSave() }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let dup = duplicateItem {
                Text("\"\(dup.name)\" is already in your items. Use it instead, or create \"\(pendingName)\" as a separate item?")
            }
        }
        .onAppear {
            if let item {
                name = item.name
                notes = item.notes ?? ""
                selectedStoreIDs = Set(dataStore.stores(for: item).map(\.id))
            }
        }
    }

    private func toggleStore(_ store: StoreModel) {
        if selectedStoreIDs.contains(store.id) {
            selectedStoreIDs.remove(store.id)
        } else {
            selectedStoreIDs.insert(store.id)
        }
    }

    private func save() {
        pendingName = name.trimmingCharacters(in: .whitespaces).capitalized

        if !isEditing, let existing = allItems.first(where: {
            isSimilarItemName($0.name, pendingName)
        }) {
            duplicateItem = existing
            showDuplicateAlert = true
            return
        }

        performSave()
    }

    private func performSave() {
        let trimmedName = pendingName.isEmpty ? name.trimmingCharacters(in: .whitespaces).capitalized : pendingName
        let notesValue = notes.trimmingCharacters(in: .whitespaces)
        let finalNotes = notesValue.isEmpty ? nil : notesValue

        if var existingItem = item {
            existingItem.name = trimmedName
            existingItem.notes = finalNotes
            dataStore.updateItem(existingItem)

            // Remove from deselected stores
            for store in dataStore.stores(for: existingItem) {
                if !selectedStoreIDs.contains(store.id) {
                    var s = store
                    s.itemIDs.removeAll { $0 == existingItem.id }
                    dataStore.updateStore(s)
                }
            }
            // Add to newly selected stores
            for storeID in selectedStoreIDs {
                if var s = dataStore.stores.first(where: { $0.id == storeID }) {
                    if !s.itemIDs.contains(existingItem.id) {
                        s.itemIDs.append(existingItem.id)
                        dataStore.updateStore(s)
                    }
                }
            }
        } else {
            let newItem = ItemModel(name: trimmedName, notes: finalNotes)
            dataStore.addItem(newItem)
            for storeID in selectedStoreIDs {
                if var s = dataStore.stores.first(where: { $0.id == storeID }) {
                    if !s.itemIDs.contains(newItem.id) {
                        s.itemIDs.append(newItem.id)
                        dataStore.updateStore(s)
                    }
                }
            }
        }
        dismiss()
    }
}

#Preview {
    ItemFormView()
        .environment(AppDataStore.preview)
}
