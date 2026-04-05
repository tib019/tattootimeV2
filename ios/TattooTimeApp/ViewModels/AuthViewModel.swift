import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let auth = FirebaseAuthService.shared
    private let userService = UserService.shared

    var isAuthenticated: Bool { auth.isAuthenticated }
    var isAdmin: Bool { currentUser?.isAdmin ?? false }

    // MARK: - Load current user profile

    func loadCurrentUser() async {
        guard let uid = auth.userId else { return }
        do {
            currentUser = try await userService.getUser(uid)
        } catch {
            // User doc may not exist yet on first launch
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await auth.signIn(email: email, password: password)
            await loadCurrentUser()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Register

    func register(email: String, password: String, displayName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await auth.signUp(email: email, password: password)
            let user = AppUser(
                id: response.localId,
                email: email,
                displayName: displayName
            )
            try await userService.createUser(user)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sign Out

    func signOut() {
        auth.signOut()
        currentUser = nil
    }
}
