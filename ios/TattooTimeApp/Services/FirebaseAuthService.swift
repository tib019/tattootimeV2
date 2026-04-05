import Foundation

// MARK: - Response types

struct AuthResponse: Decodable {
    let idToken: String
    let refreshToken: String
    let localId: String
    let email: String
}

struct TokenRefreshResponse: Decodable {
    let id_token: String
    let refresh_token: String
}

// MARK: - FirebaseAuthService

@MainActor
final class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()

    @Published private(set) var idToken: String?
    @Published private(set) var userId: String?

    private var refreshToken: String?
    private let tokenKey = "tt_idToken"
    private let refreshKey = "tt_refreshToken"
    private let userIdKey = "tt_userId"

    private init() {
        idToken      = UserDefaults.standard.string(forKey: tokenKey)
        refreshToken = UserDefaults.standard.string(forKey: refreshKey)
        userId       = UserDefaults.standard.string(forKey: userIdKey)
    }

    var isAuthenticated: Bool { idToken != nil && userId != nil }

    // MARK: Sign In

    func signIn(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(FirebaseConfig.authURL)/accounts:signInWithPassword?key=\(FirebaseConfig.apiKey)")!
        let body = ["email": email, "password": password, "returnSecureToken": true] as [String: Any]
        let response: AuthResponse = try await post(url: url, body: body)
        save(response)
        return response
    }

    // MARK: Sign Up

    func signUp(email: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(FirebaseConfig.authURL)/accounts:signUp?key=\(FirebaseConfig.apiKey)")!
        let body = ["email": email, "password": password, "returnSecureToken": true] as [String: Any]
        let response: AuthResponse = try await post(url: url, body: body)
        save(response)
        return response
    }

    // MARK: Refresh Token

    func refreshIfNeeded() async throws {
        guard let rt = refreshToken else { throw AppError.notAuthenticated }
        let url = URL(string: "https://securetoken.googleapis.com/v1/token?key=\(FirebaseConfig.apiKey)")!
        let body = ["grant_type": "refresh_token", "refresh_token": rt]
        let resp: TokenRefreshResponse = try await post(url: url, body: body)
        idToken      = resp.id_token
        refreshToken = resp.refresh_token
        UserDefaults.standard.set(resp.id_token, forKey: tokenKey)
        UserDefaults.standard.set(resp.refresh_token, forKey: refreshKey)
    }

    // MARK: Sign Out

    func signOut() {
        idToken      = nil
        refreshToken = nil
        userId       = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }

    // MARK: Private

    private func save(_ response: AuthResponse) {
        idToken      = response.idToken
        refreshToken = response.refreshToken
        userId       = response.localId
        UserDefaults.standard.set(response.idToken,      forKey: tokenKey)
        UserDefaults.standard.set(response.refreshToken, forKey: refreshKey)
        UserDefaults.standard.set(response.localId,      forKey: userIdKey)
    }

    private func post<T: Decodable>(url: URL, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if let errorBody = try? JSONDecoder().decode(FirebaseErrorResponse.self, from: data) {
                throw AppError.firebase(errorBody.error.message)
            }
            throw AppError.httpError(http.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Error helpers

struct FirebaseErrorResponse: Decodable {
    struct Inner: Decodable { let message: String }
    let error: Inner
}

enum AppError: LocalizedError {
    case notAuthenticated
    case firebase(String)
    case httpError(Int)
    case decode(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:   return "Nicht angemeldet."
        case .firebase(let msg):  return firebaseMessage(msg)
        case .httpError(let c):   return "Serverfehler (\(c))."
        case .decode(let msg):    return "Datenfehler: \(msg)"
        }
    }

    private func firebaseMessage(_ msg: String) -> String {
        switch msg {
        case "EMAIL_NOT_FOUND":          return "E-Mail nicht gefunden."
        case "INVALID_PASSWORD":         return "Falsches Passwort."
        case "USER_DISABLED":            return "Konto gesperrt."
        case "EMAIL_EXISTS":             return "E-Mail bereits registriert."
        case "WEAK_PASSWORD : Password should be at least 6 characters":
            return "Passwort muss mindestens 6 Zeichen haben."
        default:                         return msg
        }
    }
}
