import SwiftUI

@main
struct ShopSmartWatchApp: App {
    @State private var session = WatchSession()

    var body: some Scene {
        WindowGroup {
            WatchListsView()
                .environment(session)
        }
    }
}
