import SwiftUI
import PhotosUI

struct ItemFormView: View {
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss

    var item: ItemModel?

    @State private var name = ""
    @State private var brand = ""
    @State private var selectedStoreIDs: Set<String> = []
    @State private var duplicateItem: ItemModel? = nil
    @State private var showDuplicateAlert = false
    @State private var pendingName: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var itemImage: UIImage?

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
                Section {
                    TextField("e.g. Organic Milk", text: $name)
                } header: {
                    HStack(spacing: 2) {
                        Text("Item Name")
                        Text("*").foregroundStyle(.red)
                    }
                }
                Section("Brand") {
                    TextField("e.g. Organic Valley", text: $brand)
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
                    HStack(spacing: 2) {
                        Text("Available At")
                        Text("*").foregroundStyle(.red)
                    }
                } footer: {
                    if !allStores.isEmpty && selectedStoreIDs.isEmpty {
                        Text("Select at least one store to save this item.")
                            .foregroundStyle(.red)
                    }
                }
                Section("Image") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let itemImage {
                            Image(uiImage: itemImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Label("Select Photo", systemImage: "photo")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    if itemImage != nil {
                        Button("Remove Photo", role: .destructive) {
                            itemImage = nil
                            selectedPhoto = nil
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
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  (!allStores.isEmpty && selectedStoreIDs.isEmpty))
                }
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    itemImage = image.resized(maxDimension: 400)
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
                brand = item.brand ?? ""
                selectedStoreIDs = Set(dataStore.stores(for: item).map(\.id))
                if let data = item.imageData {
                    itemImage = UIImage(data: data)
                }
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
        let brandValue = brand.trimmingCharacters(in: .whitespaces)
        let finalBrand = brandValue.isEmpty ? nil : brandValue
        let finalImageData = itemImage?.resized(maxDimension: 400).jpegData(compressionQuality: 0.7)

        if var existingItem = item {
            existingItem.name = trimmedName
            existingItem.brand = finalBrand
            existingItem.imageData = finalImageData
            dataStore.updateItem(existingItem)

            for store in dataStore.stores(for: existingItem) {
                if !selectedStoreIDs.contains(store.id) {
                    var s = store
                    s.itemIDs.removeAll { $0 == existingItem.id }
                    dataStore.updateStore(s)
                }
            }
            for storeID in selectedStoreIDs {
                if var s = dataStore.stores.first(where: { $0.id == storeID }) {
                    if !s.itemIDs.contains(existingItem.id) {
                        s.itemIDs.append(existingItem.id)
                        dataStore.updateStore(s)
                    }
                }
            }
        } else {
            let newItem = ItemModel(name: trimmedName, brand: finalBrand, imageData: finalImageData)
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
