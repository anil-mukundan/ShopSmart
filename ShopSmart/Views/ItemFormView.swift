import SwiftUI
import SwiftData

struct ItemFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Store.name) private var allStores: [Store]
    @Query(sort: \Item.name) private var allItems: [Item]

    var item: Item?

    @State private var name = ""
    @State private var notes = ""
    @State private var selectedStoreIDs: Set<PersistentIdentifier> = []
    @State private var duplicateItem: Item? = nil
    @State private var showDuplicateAlert = false
    @State private var pendingName: String = ""

    private var isEditing: Bool { item != nil }

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
                Section("Available At") {
                    if allStores.isEmpty {
                        Text("Add stores in the Stores tab first.")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    } else {
                        ForEach(allStores, id: \.id) { (store: Store) in
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
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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
                selectedStoreIDs = Set(item.stores.map(\.id))
            }
        }
    }

    private func toggleStore(_ store: Store) {
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
        let selectedStores = allStores.filter { selectedStoreIDs.contains($0.id) }

        if let item {
            item.name = trimmedName
            item.notes = finalNotes
            item.stores = selectedStores
        } else {
            let newItem = Item(name: trimmedName, notes: finalNotes)
            newItem.stores = selectedStores
            modelContext.insert(newItem)
        }
        dismiss()
    }
}

#Preview {
    ItemFormView()
        .modelContainer(for: [Item.self, Store.self], inMemory: true)
}
