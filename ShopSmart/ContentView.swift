import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @Environment(AuthManager.self) private var authManager
    @State private var selectedTab = 0

    var body: some View {
        if !hasSeenOnboarding {
            OnboardingView()
        } else if authManager.isSignedIn {
            TabView(selection: $selectedTab) {
                ShopTab(selectedTab: $selectedTab)
                    .tabItem { Label("Shop", systemImage: "basket.fill") }
                    .tag(0)
                ListsTab()
                    .tabItem { Label("Lists", systemImage: "list.bullet.clipboard.fill") }
                    .tag(1)
                ItemsTab()
                    .tabItem { Label("Items", systemImage: "tag.fill") }
                    .tag(2)
                StoresTab()
                    .tabItem { Label("Stores", systemImage: "storefront.fill") }
                    .tag(3)
                SettingsTab()
                    .tabItem { Label("Settings", systemImage: "gear") }
                    .tag(4)
            }
        } else {
            AuthView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
        .environment(AppDataStore.preview)
}
