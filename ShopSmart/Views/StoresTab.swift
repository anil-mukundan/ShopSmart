import SwiftUI

struct StoresTab: View {
    @Environment(AppDataStore.self) private var dataStore
    @Environment(LocationManager.self) private var locationManager

    @State private var showAddStore = false
    @State private var storeToEdit: StoreModel?
    @State private var showHelp = false

    private var stores: [StoreModel] {
        locationManager.sorted(dataStore.stores)
    }

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
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHelp = true } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddStore) {
                StoreFormView()
            }
            .sheet(item: $storeToEdit) { store in
                StoreFormView(store: store)
            }
            .sheet(isPresented: $showHelp) {
                OnboardingView(startPage: 2, helpMode: true)
            }
        }
    }

    private func deleteStores(at offsets: IndexSet) {
        for index in offsets {
            dataStore.deleteStore(id: stores[index].id)
        }
    }
}

private struct StoreRow: View {
    let store: StoreModel
    @Environment(AppDataStore.self) private var dataStore
    @Environment(LocationManager.self) private var locationManager

    var body: some View {
        HStack(spacing: 12) {
            StoreLogo(store: store)
            VStack(alignment: .leading, spacing: 3) {
                Text(store.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                let count = dataStore.items(for: store).count
                Text("\(count) item\(count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let location = store.locationName {
                    HStack(spacing: 4) {
                        Label(location, systemImage: "mappin")
                            .lineLimit(1)
                        if let dist = locationManager.distanceString(to: store) {
                            Text("·")
                            Text(dist)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    StoresTab()
        .environment(AppDataStore.preview)
}
