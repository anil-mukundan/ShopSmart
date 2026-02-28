import SwiftUI

struct SettingsTab: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let email = authManager.user?.email {
                        LabeledContent("Signed in as", value: email)
                    }
                    Button("Sign Out", role: .destructive) {
                        try? authManager.signOut()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsTab()
        .environment(AuthManager())
}
