import SwiftUI

struct WatchListsView: View {
    @Environment(WatchSession.self) private var session

    var body: some View {
        NavigationStack {
            Group {
                if session.lists.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No Lists")
                            .font(.headline)
                        Text("Create a list in the iPhone app")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(session.lists) { list in
                        NavigationLink(destination: WatchListDetailView(listID: list.id)) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(list.storeName)
                                    .font(.headline)
                                let remaining = list.uncheckedCount
                                let total     = list.totalCount
                                Text(remaining == 0
                                     ? "All done!"
                                     : "\(remaining) of \(total) remaining")
                                    .font(.caption2)
                                    .foregroundStyle(remaining == 0 ? .green : .secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("ShopSmart")
        }
    }
}
