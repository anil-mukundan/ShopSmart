import SwiftUI
import PhotosUI

struct CreateItemView: View {
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss

    let currentStoreName: String
    let currentStoreID: String?
    let onItemCreated: (ItemModel) -> Void

    @State private var name = ""
    @State private var brand = ""
    @State private var selectedStoreIDs: Set<String> = []
    @State private var duplicateItem: ItemModel? = nil
    @State private var showDuplicateAlert = false
    @State private var pendingName: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var itemImage: UIImage?

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
                Section("Brand") {
                    TextField("e.g. Silk", text: $brand)
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
        .onChange(of: selectedPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    itemImage = image.resized(maxDimension: 400)
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
        let brandValue = brand.trimmingCharacters(in: .whitespaces)
        let finalBrand = brandValue.isEmpty ? nil : brandValue
        let finalImageData = itemImage?.resized(maxDimension: 400).jpegData(compressionQuality: 0.7)

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

        onItemCreated(newItem)
        dismiss()
    }
}

#Preview {
    CreateItemView(currentStoreName: "Whole Foods", currentStoreID: nil) { _ in }
        .environment(AppDataStore.preview)
}
