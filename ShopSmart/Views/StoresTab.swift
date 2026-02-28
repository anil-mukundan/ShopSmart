import SwiftUI
import SwiftData

struct StoresTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Store.name) private var stores: [Store]

    @State private var showAddStore = false
    @State private var storeToEdit: Store?

    var body: some View {
        NavigationStack {
            List {
                ForEach(stores) { store in
                    Button { storeToEdit = store } label: {
                        StoreRow(store: store)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteStores)
            }
            .navigationTitle("Stores")
            .overlay {
                if stores.isEmpty {
                    ContentUnavailableView(
                        "No Stores",
                        systemImage: "storefront",
                        description: Text("Tap + to add your first store.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showAddStore = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddStore) {
                StoreFormView()
            }
            .sheet(item: $storeToEdit) { store in
                StoreFormView(store: store)
            }
        }
    }

    private func deleteStores(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(stores[index])
        }
    }
}

private struct StoreRow: View {
    let store: Store

    var body: some View {
        HStack(spacing: 12) {
            StoreLogo(store: store)
            VStack(alignment: .leading, spacing: 3) {
                Text(store.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let notes = store.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(store.items.count) item\(store.items.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    StoresTab()
        .modelContainer(for: [Store.self, Item.self], inMemory: true)
}
