import SwiftUI

struct ShoppingListDetailView: View {
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss

    let shoppingList: ShoppingListModel

    @State private var showDeleteConfirmation = false
    @State private var showIncompleteDeleteWarning = false
    @State private var showAddItem = false
    @State private var showAddFromStore = false
    @State private var editMode: EditMode = .inactive

    private var store: StoreModel? {
        dataStore.stores.first { $0.id == shoppingList.storeID }
    }

    private var sortedEntries: [ShoppingListEntryModel] {
        dataStore.sortedEntries(for: shoppingList)
    }

    private var allEntries: [ShoppingListEntryModel] {
        dataStore.entries(forListID: shoppingList.id)
    }

    private var cartCount: Int { allEntries.filter(\.isInCart).count }
    private var total: Int { allEntries.count }
    private var allDone: Bool { total > 0 && cartCount == total }

    var body: some View {
        List {
            if !sortedEntries.isEmpty {
                Section {
                    ForEach(sortedEntries) { entry in
                        EntryRow(entry: entry)
                    }
                    .onMove(perform: moveEntries)
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: allDone ? "checkmark.circle.fill" : "cart")
                            .foregroundStyle(allDone ? .green : .appAccent)
                        Text(allDone ? "All items in cart!" : "\(cartCount) of \(total) in cart")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(allDone ? .green : .secondary)
                    }
                    .padding(.leading, 4)
                    .padding(.bottom, 2)
                    .textCase(nil)
                }
            }
        }
        .environment(\.editMode, $editMode)
        .navigationTitle(shoppingList.storeName)
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if allEntries.isEmpty {
                ContentUnavailableView(
                    "Empty List",
                    systemImage: "cart",
                    description: Text("This shopping list has no items.")
                )
            }
        }
        .sheet(isPresented: $showAddItem) {
            if let store {
                AddItemToListView(shoppingList: shoppingList, currentStore: store)
            }
        }
        .sheet(isPresented: $showAddFromStore) {
            if let store {
                AddFromStoreView(shoppingList: shoppingList, store: store)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Text(allDone ? "Done!" : "\(cartCount)/\(total)")
                        .font(.subheadline.weight(allDone ? .semibold : .regular))
                        .foregroundStyle(allDone ? .green : .secondary)
                    if total >= 2 && store != nil {
                        Button {
                            withAnimation { editMode = editMode == .active ? .inactive : .active }
                        } label: {
                            Image(systemName: editMode == .active ? "checkmark.circle.fill" : "arrow.up.arrow.down")
                                .foregroundStyle(editMode == .active ? .green : .primary)
                        }
                    }
                    if editMode == .inactive {
                        if store != nil {
                            Menu {
                                Button { showAddFromStore = true } label: {
                                    Label("Add from Store Catalog", systemImage: "cart.badge.plus")
                                }
                                Button { showAddItem = true } label: {
                                    Label("Create New Item", systemImage: "plus.circle")
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                        Button(role: .destructive) {
                            if allDone || total == 0 {
                                deleteList()
                            } else {
                                showIncompleteDeleteWarning = true
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
        .alert("Delete List?", isPresented: $showIncompleteDeleteWarning) {
            Button("Delete", role: .destructive) { deleteList() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You still have \(total - cartCount) unpurchased item\(total - cartCount == 1 ? "" : "s"). Are you sure you want to delete this list?")
        }
        .onShake {
            if cartCount > 0 {
                removeCheckedItems()
            }
        }
        .onChange(of: allDone) { _, newValue in
            if newValue {
                showDeleteConfirmation = true
            }
        }
        .alert("All Items Purchased!", isPresented: $showDeleteConfirmation) {
            Button("Delete List", role: .destructive) { deleteList() }
            Button("Keep List", role: .cancel) { }
        } message: {
            Text("Every item has been added to your cart. Would you like to delete this shopping list?")
        }
    }

    private func moveEntries(from source: IndexSet, to destination: Int) {
        var reordered = sortedEntries
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, entry) in reordered.enumerated() {
            dataStore.updateSortOrder(storeID: shoppingList.storeID, itemID: entry.itemID, sortOrder: index)
        }
    }

    private func deleteList() {
        dataStore.deleteShoppingList(id: shoppingList.id)
        dismiss()
    }

    private func removeCheckedItems() {
        dataStore.entries(forListID: shoppingList.id)
            .filter(\.isInCart)
            .forEach { dataStore.deleteEntry(id: $0.id) }
    }
}

// MARK: - Entry Row

private struct EntryRow: View {
    let entry: ShoppingListEntryModel
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.editMode) private var editMode

    @State private var showDetail = false

    private var itemHasDetails: Bool {
        guard let item = dataStore.items.first(where: { $0.id == entry.itemID }) else { return false }
        return item.imageData != nil || (item.brand?.isEmpty == false)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isInCart ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(entry.isInCart ? .green : Color(.tertiaryLabel))
                .frame(width: 28)
                .animation(.easeInOut(duration: 0.2), value: entry.isInCart)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(entry.itemName)
                        .font(.body.weight(.medium))
                        .strikethrough(entry.isInCart, color: .secondary)
                        .foregroundStyle(entry.isInCart ? .tertiary : .primary)
                    if entry.count > 1 {
                        Text("×\(entry.count)")
                            .font(.subheadline)
                            .foregroundStyle(entry.isInCart ? .quaternary : .secondary)
                    }
                }
            }

            Spacer()

            if editMode?.wrappedValue != .active && itemHasDetails {
                Button {
                    showDetail = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .onTapGesture {
            guard editMode?.wrappedValue != .active else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                dataStore.toggleEntryInCart(id: entry.id)
            }
        }
        .sheet(isPresented: $showDetail) {
            if let item = dataStore.items.first(where: { $0.id == entry.itemID }) {
                ItemDetailSheet(item: item)
            }
        }
    }
}

// MARK: - Item Detail Sheet

private struct ItemDetailSheet: View {
    let item: ItemModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let data = item.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    if let brand = item.brand, !brand.isEmpty {
                        LabeledContent("Brand", value: brand)
                            .padding(.horizontal, 4)
                    }
                }
                .padding()
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let store = AppDataStore.preview
    let list = ShoppingListModel(id: "l1", storeID: "s1", storeName: "Whole Foods")
    store.shoppingLists = [list]
    store.entries = [
        ShoppingListEntryModel(id: "e1", listID: "l1", itemID: "i1", itemName: "Organic Milk", isInCart: true),
        ShoppingListEntryModel(id: "e2", listID: "l1", itemID: "i2", itemName: "Sourdough Bread"),
        ShoppingListEntryModel(id: "e3", listID: "l1", itemID: "i3", itemName: "Fuji Apples")
    ]
    return NavigationStack {
        ShoppingListDetailView(shoppingList: list)
    }
    .environment(store)
}
