import SwiftUI

struct CreateItemView: View {
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss

    let currentStoreName: String
    let currentStoreID: String?
    let onItemCreated: (ItemModel) -> Void

    @State private var name = ""
    @State private var notes = ""
    @State private var selectedStoreIDs: Set<String> = []
    @State private var duplicateItem: ItemModel? = nil
    @State private var showDuplicateAlert = false
    @State private var pendingName: String = ""

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
                    TextField("e.g. Almond Milk", text: $name)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    if allStores.isEmpty {
                        Text("No other stores added yet.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(allStores, id: \.id) { store in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.name)
                                    if store.id == currentStoreID {
                                        Text("Current store — always included")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if selectedStoreIDs.contains(store.id) {
                                    Image(systemName: store.id == currentStoreID ? "checkmark.circle.fill" : "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { toggleStore(store) }
                        }
                    }
                } header: {
                    Text("Also Available At")
                } footer: {
                    if !allStores.isEmpty && selectedStoreIDs.isEmpty {
                        Text("Select at least one store to save this item.")
                            .foregroundStyle(.red)
                    } else if currentStoreID == nil, !currentStoreName.isEmpty {
                        Text("This item will automatically be added to \(currentStoreName).")
                    }
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  (!allStores.isEmpty && selectedStoreIDs.isEmpty))
                }
            }
        }
        .alert("Item Already Exists", isPresented: $showDuplicateAlert) {
            Button("Use Existing") {
                if let existing = duplicateItem { onItemCreated(existing) }
                dismiss()
            }
            Button("Create Anyway", role: .destructive) { performSave() }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let dup = duplicateItem {
                Text("\"\(dup.name)\" is already in your items. Add it to this list instead, or create \"\(pendingName)\" as a separate item?")
            }
        }
        .onAppear {
            if let id = currentStoreID {
                selectedStoreIDs.insert(id)
            }
        }
    }

    private func toggleStore(_ store: StoreModel) {
        guard store.id != currentStoreID else { return }
        if selectedStoreIDs.contains(store.id) {
            selectedStoreIDs.remove(store.id)
        } else {
            selectedStoreIDs.insert(store.id)
        }
    }

    private func save() {
        pendingName = name.trimmingCharacters(in: .whitespaces).capitalized

        if let existing = allItems.first(where: {
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
        let finalNotes = notes.trimmingCharacters(in: .whitespaces)

        let newItem = ItemModel(
            name: trimmedName,
            notes: finalNotes.isEmpty ? nil : finalNotes
        )
        dataStore.addItem(newItem)

        for storeID in selectedStoreIDs {
            if var s = dataStore.stores.first(where: { $0.id == storeID }) {
                if !s.itemIDs.contains(newItem.id) {
                    s.itemIDs.append(newItem.id)
                    dataStore.updateStore(s)
                }
            }
        }

        onItemCreated(newItem)
        dismiss()
    }
}

#Preview {
    CreateItemView(currentStoreName: "Whole Foods", currentStoreID: nil) { _ in }
        .environment(AppDataStore.preview)
}
