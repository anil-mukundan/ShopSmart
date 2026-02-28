import SwiftUI
import SwiftData

struct ListsTab: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingList.date, order: .reverse) private var lists: [ShoppingList]

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    ContentUnavailableView(
                        "No Shopping Lists",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Create a shopping list in the Shop tab.")
                    )
                } else {
                    List {
                        ForEach(lists) { list in
                            NavigationLink {
                                ShoppingListDetailView(shoppingList: list)
                            } label: {
                                ShoppingListRow(list: list)
                            }
                        }
                        .onDelete(perform: deleteLists)
                    }
                }
            }
            .navigationTitle("Lists")
            .toolbar {
                if !lists.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
        }
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(lists[index])
        }
    }
}

private struct ShoppingListRow: View {
    let list: ShoppingList

    private var cartCount: Int { list.entries.filter(\.isInCart).count }
    private var total: Int { list.entries.count }
    private var allDone: Bool { total > 0 && cartCount == total }

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(
                systemName: allDone ? "checkmark.circle.fill" : "cart.fill",
                color: allDone ? .green : .appAccent
            )
            VStack(alignment: .leading, spacing: 5) {
                Text(list.storeName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                HStack(spacing: 4) {
                    Text(list.date, style: .date)
                    Text("·")
                    Text("\(total) item\(total == 1 ? "" : "s")")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if total > 0 {
                    ProgressView(value: Double(cartCount), total: Double(total))
                        .progressViewStyle(.linear)
                        .tint(allDone ? .green : .appAccent)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    ListsTab()
        .modelContainer(
            for: [Store.self, Item.self, ShoppingList.self, ShoppingListEntry.self],
            inMemory: true
        )
}
