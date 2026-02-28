import SwiftUI
import SwiftData

struct ShoppingListDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let shoppingList: ShoppingList

    @Query private var allFrequencies: [StoreItemFrequency]

    @State private var showDeleteConfirmation = false
    @State private var showIncompleteDeleteWarning = false
    @State private var showAddItem = false
    @State private var showAddFromStore = false
    @State private var editMode: EditMode = .inactive

    private var sortedEntries: [ShoppingListEntry] {
        guard let storeID = shoppingList.store?.id else {
            return shoppingList.entries.sorted { ($0.item?.name ?? "") < ($1.item?.name ?? "") }
        }
        var orderMap: [PersistentIdentifier: Int] = [:]
        for freq in allFrequencies where freq.store?.id == storeID {
            if let itemID = freq.item?.id { orderMap[itemID] = freq.sortOrder }
        }
        return shoppingList.entries.sorted { a, b in
            let oa = a.item.flatMap { orderMap[$0.id] } ?? Int.max
            let ob = b.item.flatMap { orderMap[$0.id] } ?? Int.max
            if oa != ob { return oa < ob }
            return (a.item?.name ?? "") < (b.item?.name ?? "")
        }
    }

    private var cartCount: Int { shoppingList.entries.filter(\.isInCart).count }
    private var total: Int { shoppingList.entries.count }
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
            if shoppingList.entries.isEmpty {
                ContentUnavailableView(
                    "Empty List",
                    systemImage: "cart",
                    description: Text("This shopping list has no items.")
                )
            }
        }
        .sheet(isPresented: $showAddItem) {
            if let store = shoppingList.store {
                AddItemToListView(shoppingList: shoppingList, currentStore: store)
            }
        }
        .sheet(isPresented: $showAddFromStore) {
            if let store = shoppingList.store {
                AddFromStoreView(shoppingList: shoppingList, store: store)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Text(allDone ? "Done!" : "\(cartCount)/\(total)")
                        .font(.subheadline.weight(allDone ? .semibold : .regular))
                        .foregroundStyle(allDone ? .green : .secondary)
                    if total >= 2 && shoppingList.store != nil {
                        Button {
                            withAnimation { editMode = editMode == .active ? .inactive : .active }
                        } label: {
                            Image(systemName: editMode == .active ? "checkmark.circle.fill" : "arrow.up.arrow.down")
                                .foregroundStyle(editMode == .active ? .green : .primary)
                        }
                    }
                    if editMode == .inactive {
                        if shoppingList.store != nil {
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
        guard let store = shoppingList.store else { return }
        var reordered = sortedEntries
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, entry) in reordered.enumerated() {
            guard let item = entry.item else { continue }
            if let freq = allFrequencies.first(where: {
                $0.store?.id == store.id && $0.item?.id == item.id
            }) {
                freq.sortOrder = index
            } else {
                let freq = StoreItemFrequency(store: store, item: item, count: 0, sortOrder: index)
                modelContext.insert(freq)
            }
        }
    }

    private func deleteList() {
        modelContext.delete(shoppingList)
        dismiss()
    }

    private func removeCheckedItems() {
        let checkedEntries = shoppingList.entries.filter(\.isInCart)
        for entry in checkedEntries {
            modelContext.delete(entry)
        }
    }
}

// MARK: - Entry Row

private struct EntryRow: View {
    @Bindable var entry: ShoppingListEntry
    @Environment(\.editMode) private var editMode

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
                if let notes = entry.item?.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(entry.isInCart ? .quaternary : .tertiary)
                        .strikethrough(entry.isInCart, color: .secondary.opacity(0.5))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .onTapGesture {
            guard editMode?.wrappedValue != .active else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                entry.isInCart.toggle()
            }
        }
    }
}

// MARK: - Preview

private struct ShoppingListDetailPreview: View {
    private let container: ModelContainer
    private let list: ShoppingList

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Store.self, Item.self, ShoppingList.self, ShoppingListEntry.self,
            configurations: config
        )
        let ctx = container.mainContext

        let store = Store(name: "Whole Foods")
        let item1 = Item(name: "Organic Milk", notes: "Full-fat, 1 gallon")
        let item2 = Item(name: "Sourdough Bread")
        let item3 = Item(name: "Fuji Apples")
        ctx.insert(store)
        ctx.insert(item1)
        ctx.insert(item2)
        ctx.insert(item3)

        let list = ShoppingList(store: store)
        ctx.insert(list)

        let e1 = ShoppingListEntry(item: item1, isInCart: true)
        let e2 = ShoppingListEntry(item: item2)
        let e3 = ShoppingListEntry(item: item3)
        ctx.insert(e1)
        ctx.insert(e2)
        ctx.insert(e3)
        list.entries = [e1, e2, e3]

        self.container = container
        self.list = list
    }

    var body: some View {
        NavigationStack {
            ShoppingListDetailView(shoppingList: list)
        }
        .modelContainer(container)
    }
}

#Preview {
    ShoppingListDetailPreview()
}
