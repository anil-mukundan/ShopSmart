import SwiftUI
import FirebaseCore

@main
struct ShopSmartApp: App {
    @State private var authManager: AuthManager
    @State private var dataStore: AppDataStore
    private let phoneSession = PhoneSession()

    init() {
        FirebaseApp.configure()
        _authManager = State(initialValue: AuthManager())
        _dataStore = State(initialValue: AppDataStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.appAccent)
                .environment(authManager)
                .environment(dataStore)
                .task {
                    phoneSession.configure(dataStore: dataStore)
                    if let uid = authManager.user?.uid {
                        dataStore.startListening(uid: uid)
                    }
                }
                .onChange(of: authManager.user?.uid) { _, uid in
                    if let uid { dataStore.startListening(uid: uid) }
                    else { dataStore.stopListening() }
                }
                .onChange(of: dataStore.shoppingLists) { _, _ in phoneSession.pushToWatch() }
                .onChange(of: dataStore.entries)       { _, _ in phoneSession.pushToWatch() }
                .onChange(of: dataStore.items)         { _, _ in phoneSession.pushToWatch() }
        }
    }
}
