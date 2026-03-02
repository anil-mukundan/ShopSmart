import SwiftUI

struct ItemsTab: View {
    @Environment(AppDataStore.self) private var dataStore

    @State private var showAddItem = false
    @State private var itemToEdit: ItemModel?
    @State private var searchText = ""
    @FocusState private var searchIsFocused: Bool
    @State private var showHelp = false

    private var items: [ItemModel] {
        dataStore.items.sorted { $0.name < $1.name }
    }

    private var filteredItems: [ItemModel] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredItems) { item in
                    Button { itemToEdit = item } label: {
                        ItemRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Items")
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "tag",
                        description: Text("Tap + to add your first item.")
                    )
                } else if filteredItems.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search items", text: $searchText)
                        .autocorrectionDisabled()
                        .focused($searchIsFocused)
                    if searchIsFocused || !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchIsFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddItem = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHelp = true } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                ItemFormView()
            }
            .sheet(item: $itemToEdit) { item in
                ItemFormView(item: item)
            }
            .sheet(isPresented: $showHelp) {
                OnboardingView(startPage: 3, helpMode: true)
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            for store in dataStore.stores(for: item) {
                var updatedStore = store
                updatedStore.itemIDs.removeAll { $0 == item.id }
                dataStore.updateStore(updatedStore)
            }
            dataStore.deleteItem(id: item.id)
        }
    }
}

private struct ItemRow: View {
    let item: ItemModel
    @Environment(AppDataStore.self) private var dataStore

    var body: some View {
        HStack(spacing: 12) {
            if let data = item.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                IconBadge(systemName: "tag.fill")
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let brand = item.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                let storeNames = dataStore.stores(for: item).map(\.name).sorted()
                if !storeNames.isEmpty {
                    Text(storeNames.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    ItemsTab()
        .environment(AppDataStore.preview)
}
