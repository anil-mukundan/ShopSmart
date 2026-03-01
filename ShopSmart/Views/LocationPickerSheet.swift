import SwiftUI
import MapKit

struct LocationPickerSheet: View {
    let initialQuery: String
    let onSelect: (String, Double, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""
    @State private var results: [MKMapItem] = []
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if results.isEmpty {
                    Text(query.isEmpty ? "Enter a store name to search." : "No results found.")
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(results, id: \.self) { item in
                        Button { select(item) } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name ?? "Unknown")
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                if let address = formattedAddress(item.placemark) {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search for store location"
            )
            .onSubmit(of: .search) { performSearch() }
            .onChange(of: query) { _, newQuery in
                if newQuery.isEmpty { results = [] }
            }
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            query = initialQuery
            if !initialQuery.isEmpty { performSearch() }
        }
    }

    private func select(_ item: MKMapItem) {
        guard let location = item.placemark.location else { return }
        let placeName = item.name ?? query
        let address = formattedAddress(item.placemark)
        let displayName = address != nil ? "\(placeName), \(address!)" : placeName
        onSelect(displayName, location.coordinate.latitude, location.coordinate.longitude)
        dismiss()
    }

    private func performSearch() {
        guard !query.isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        Task {
            let response = try? await MKLocalSearch(request: request).start()
            await MainActor.run {
                results = response?.mapItems ?? []
                isSearching = false
            }
        }
    }

    private func formattedAddress(_ placemark: MKPlacemark) -> String? {
        let parts = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
