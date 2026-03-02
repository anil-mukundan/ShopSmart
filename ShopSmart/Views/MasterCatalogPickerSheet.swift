import SwiftUI

struct MasterCatalogPickerSheet: View {
    @Environment(AppDataStore.self) private var dataStore
    @Environment(\.dismiss) private var dismiss

    let store: StoreModel
    let onAdd: ([ItemModel]) -> Void

    @State private var selectedIDs: Set<String> = []
    @State private var searchText = ""

    private var candidates: [ItemModel] {
        dataStore.items
            .filter { !store.itemIDs.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    private var filteredCandidates: [ItemModel] {
        guard !searchText.isEmpty else { return candidates }
        return candidates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if candidates.isEmpty {
                    ContentUnavailableView(
                        "All Items Assigned",
                        systemImage: "checkmark.circle",
                        description: Text("Every item in your catalog is already available at \(store.name).")
                    )
                } else if filteredCandidates.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List {
                        ForEach(filteredCandidates) { item in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let brand = item.brand, !brand.isEmpty {
                                        Text(brand)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: selectedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIDs.contains(item.id) ? Color.appAccent : Color.secondary)
                                    .font(.title3)
                                    .animation(.easeInOut(duration: 0.15), value: selectedIDs.contains(item.id))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedIDs.contains(item.id) { selectedIDs.remove(item.id) }
                                else { selectedIDs.insert(item.id) }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search items")
            .navigationTitle("Master Catalog")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedIDs.count))") {
                        let selected = candidates.filter { selectedIDs.contains($0.id) }
                        // Add selected items to the store's catalog for future use
                        var updatedStore = store
                        for item in selected where !updatedStore.itemIDs.contains(item.id) {
                            updatedStore.itemIDs.append(item.id)
                        }
                        dataStore.updateStore(updatedStore)
                        onAdd(selected)
                        dismiss()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
        }
    }
}
