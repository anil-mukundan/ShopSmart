import FirebaseFirestore

@Observable
final class AppDataStore {
    var stores: [StoreModel] = []
    var items: [ItemModel] = []
    var shoppingLists: [ShoppingListModel] = []
    var entries: [ShoppingListEntryModel] = []
    var frequencies: [FrequencyModel] = []

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var uid: String = ""

    // MARK: - Listeners

    func startListening(uid: String) {
        stopListening()
        self.uid = uid
        attach("stores") { [weak self] (decoded: [StoreModel]) in self?.stores = decoded }
        attach("items") { [weak self] (decoded: [ItemModel]) in self?.items = decoded }
        attach("shoppingLists") { [weak self] (decoded: [ShoppingListModel]) in self?.shoppingLists = decoded }
        attach("shoppingListEntries") { [weak self] (decoded: [ShoppingListEntryModel]) in self?.entries = decoded }
        attach("frequencies") { [weak self] (decoded: [FrequencyModel]) in self?.frequencies = decoded }
    }

    private func attach<T: Codable>(_ name: String, update: @escaping ([T]) -> Void) {
        let ref = db.collection("users").document(uid).collection(name)
        let listener = ref.addSnapshotListener { snap, _ in
            let decoded = snap?.documents.compactMap { try? $0.data(as: T.self) } ?? []
            DispatchQueue.main.async { update(decoded) }
        }
        listeners.append(listener)
    }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners = []
        stores = []; items = []; shoppingLists = []; entries = []; frequencies = []
    }

    // MARK: - Collection reference helper

    private func col(_ name: String) -> CollectionReference {
        db.collection("users").document(uid).collection(name)
    }

    // MARK: - Stores CRUD

    func addStore(_ s: StoreModel)    { save(s, to: "stores") }
    func updateStore(_ s: StoreModel) { save(s, to: "stores") }
    func deleteStore(id: String)      { delete(id: id, from: "stores") }

    // MARK: - Items CRUD

    func addItem(_ i: ItemModel)    { save(i, to: "items") }
    func updateItem(_ i: ItemModel) { save(i, to: "items") }
    func deleteItem(id: String)     { delete(id: id, from: "items") }

    // MARK: - Shopping Lists CRUD

    func addShoppingList(_ l: ShoppingListModel)    { save(l, to: "shoppingLists") }
    func updateShoppingList(_ l: ShoppingListModel) { save(l, to: "shoppingLists") }
    func deleteShoppingList(id: String) {
        delete(id: id, from: "shoppingLists")
        Task {
            let snap = try? await col("shoppingListEntries")
                .whereField("listID", isEqualTo: id).getDocuments()
            for doc in snap?.documents ?? [] {
                try? await doc.reference.delete()
            }
        }
    }

    // MARK: - Entries CRUD

    func addEntry(_ e: ShoppingListEntryModel)    { save(e, to: "shoppingListEntries") }
    func updateEntry(_ e: ShoppingListEntryModel) { save(e, to: "shoppingListEntries") }
    func deleteEntry(id: String)                  { delete(id: id, from: "shoppingListEntries") }

    func toggleEntryInCart(id: String) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        var updated = entries[idx]
        updated.isInCart.toggle()
        updateEntry(updated)
    }

    // MARK: - Frequencies

    func upsertFrequency(_ f: FrequencyModel) { save(f, to: "frequencies") }

    func incrementFrequency(storeID: String, itemID: String) {
        if let existing = frequencies.first(where: { $0.storeID == storeID && $0.itemID == itemID }) {
            var updated = existing
            updated.count += 1
            upsertFrequency(updated)
        } else {
            upsertFrequency(FrequencyModel(storeID: storeID, itemID: itemID))
        }
    }

    func updateSortOrder(storeID: String, itemID: String, sortOrder: Int) {
        if let existing = frequencies.first(where: { $0.storeID == storeID && $0.itemID == itemID }) {
            var updated = existing
            updated.sortOrder = sortOrder
            upsertFrequency(updated)
        } else {
            upsertFrequency(FrequencyModel(storeID: storeID, itemID: itemID, count: 0, sortOrder: sortOrder))
        }
    }

    // MARK: - Generic save / delete

    private func save<T: Codable & Identifiable>(_ obj: T, to collection: String) where T.ID == String {
        Task { try? await col(collection).document(obj.id).setData(from: obj) }
    }

    private func delete(id: String, from collection: String) {
        Task { try? await col(collection).document(id).delete() }
    }

    // MARK: - Convenience helpers

    func items(for store: StoreModel) -> [ItemModel] {
        items.filter { store.itemIDs.contains($0.id) }
    }

    func stores(for item: ItemModel) -> [StoreModel] {
        stores.filter { $0.itemIDs.contains(item.id) }
    }

    func entries(forListID id: String) -> [ShoppingListEntryModel] {
        entries.filter { $0.listID == id }
    }

    func sortedEntries(for list: ShoppingListModel) -> [ShoppingListEntryModel] {
        let listEntries = entries(forListID: list.id)
        var orderMap: [String: Int] = [:]
        for freq in frequencies where freq.storeID == list.storeID {
            orderMap[freq.itemID] = freq.sortOrder
        }
        return listEntries.sorted { a, b in
            let oa = orderMap[a.itemID] ?? Int.max
            let ob = orderMap[b.itemID] ?? Int.max
            if oa != ob { return oa < ob }
            return a.itemName < b.itemName
        }
    }
}

// MARK: - Preview helper

extension AppDataStore {
    static var preview: AppDataStore {
        let s = AppDataStore()
        s.stores = [StoreModel(id: "s1", name: "Whole Foods", itemIDs: ["i1"])]
        s.items = [ItemModel(id: "i1", name: "Organic Milk")]
        return s
    }
}
