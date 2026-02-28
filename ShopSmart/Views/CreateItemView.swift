import SwiftUI
import SwiftData

struct CreateItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Store.name) private var allStores: [Store]
    @Query(sort: \Item.name) private var allItems: [Item]

    /// Display name of the store this item is being created from.
    let currentStoreName: String
    /// Persistent ID of the store when editing an existing one; nil when the store is new.
    let currentStoreID: PersistentIdentifier?
    /// Called with the newly created item so the caller can react (e.g. auto-select it).
    let onItemCreated: (Item) -> Void

    @State private var name = ""
    @State private var notes = ""
    @State private var selectedStoreIDs: Set<PersistentIdentifier> = []
    @State private var duplicateItem: Item? = nil
    @State private var showDuplicateAlert = false
    @State private var pendingName: String = ""

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
                        ForEach(allStores, id: \.id) { (store: Store) in
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
                    if currentStoreID == nil, !currentStoreName.isEmpty {
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
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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

    private func toggleStore(_ store: Store) {
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

        let newItem = Item(
            name: trimmedName,
            notes: finalNotes.isEmpty ? nil : finalNotes
        )
        newItem.stores = allStores.filter { selectedStoreIDs.contains($0.id) }
        modelContext.insert(newItem)

        onItemCreated(newItem)
        dismiss()
    }
}

#Preview {
    CreateItemView(currentStoreName: "Whole Foods", currentStoreID: nil) { _ in }
        .modelContainer(for: [Store.self, Item.self], inMemory: true)
}
