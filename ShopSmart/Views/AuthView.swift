import SwiftUI

struct AuthView: View {
    @Environment(AuthManager.self) private var authManager

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $password)
                } header: {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                        .padding(.bottom, 8)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(isSignUp ? "Create Account" : "Log In")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .tint(.appAccent)
                    .controlSize(.large)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    Button {
                        isSignUp.toggle()
                        errorMessage = nil
                    } label: {
                        Text(isSignUp ? "Already have an account? Log In" : "No account? Create one")
                            .frame(maxWidth: .infinity)
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.appAccent)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("ShopSmart")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func submit() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthManager())
}
