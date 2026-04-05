import Foundation

struct AppUser: Codable, Identifiable {
    let id: String
    var email: String
    var displayName: String
    var isAdmin: Bool
    var language: String
    var createdAt: String

    init(id: String, email: String, displayName: String,
         isAdmin: Bool = false, language: String = "de",
         createdAt: String = ISO8601DateFormatter().string(from: Date())) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.isAdmin = isAdmin
        self.language = language
        self.createdAt = createdAt
    }
}
