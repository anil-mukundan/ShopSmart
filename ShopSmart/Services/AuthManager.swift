import FirebaseAuth

@Observable
final class AuthManager {
    private(set) var user: User? = Auth.auth().currentUser
    private var listenerHandle: AuthStateDidChangeListenerHandle?

    var isSignedIn: Bool { user != nil }

    init() {
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async { self?.user = user }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
