import SwiftUI

struct WatchListDetailView: View {
    let listID: String
    @Environment(WatchSession.self) private var session

    private var list: WatchList? {
        session.lists.first { $0.id == listID }
    }

    private var sortedEntries: [WatchEntry] {
        guard let list else { return [] }
        return list.entries.sorted { a, b in
            if a.isInCart != b.isInCart { return !a.isInCart }
            return a.itemName < b.itemName
        }
    }

    var body: some View {
        List {
            if let list {
                Section {
                    ForEach(sortedEntries) { entry in
                        WatchEntryRow(entry: entry, listID: listID)
                    }
                } header: {
                    let done  = list.totalCount - list.uncheckedCount
                    let total = list.totalCount
                    HStack(spacing: 4) {
                        Image(systemName: list.uncheckedCount == 0
                              ? "checkmark.circle.fill" : "cart")
                            .foregroundStyle(list.uncheckedCount == 0 ? .green : .secondary)
                        Text(list.uncheckedCount == 0
                             ? "All in cart!"
                             : "\(done)/\(total) in cart")
                            .foregroundStyle(list.uncheckedCount == 0 ? .green : .secondary)
                    }
                    .font(.caption2)
                }
            }
        }
        .navigationTitle(list?.storeName ?? "List")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Entry Row

private struct WatchEntryRow: View {
    let entry: WatchEntry
    let listID: String
    @Environment(WatchSession.self) private var session
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: entry.isInCart ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(entry.isInCart ? .green : .secondary)
                .animation(.easeInOut(duration: 0.2), value: entry.isInCart)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.itemName)
                    .font(.body)
                    .strikethrough(entry.isInCart)
                    .foregroundStyle(entry.isInCart ? .tertiary : .primary)
                if entry.count > 1 {
                    Text("×\(entry.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if entry.hasDetails {
                Button {
                    showDetail = true
                } label: {
                    Image(systemName: entry.notes != nil
                          ? "info.circle.fill" : "info.circle")
                        .font(.footnote)
                        .foregroundStyle(entry.notes != nil
                                         ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                session.toggleEntry(id: entry.id, inList: listID)
            }
        }
        .sheet(isPresented: $showDetail) {
            WatchItemDetailView(entry: entry)
        }
    }
}
