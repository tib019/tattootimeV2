import Foundation

final class UserService {
    static let shared = UserService()
    private let db = FirestoreService.shared
    private init() {}

    func getUser(_ userId: String) async throws -> AppUser {
        let (id, fields) = try await db.getDocument(collection: "users", documentId: userId)
        guard
            let email = fields["email"]?.stringValue,
            let displayName = fields["displayName"]?.stringValue
        else { throw AppError.decode("User fields missing") }

        return AppUser(
            id: id,
            email: email,
            displayName: displayName,
            isAdmin: fields["isAdmin"]?.boolValue ?? false,
            language: fields["language"]?.stringValue ?? "de",
            createdAt: fields["createdAt"]?.stringValue ?? ""
        )
    }

    func createUser(_ user: AppUser) async throws {
        try await db.setDocument(
            collection: "users",
            documentId: user.id,
            fields: [
                "email": .string(user.email),
                "displayName": .string(user.displayName),
                "isAdmin": .bool(user.isAdmin),
                "language": .string(user.language),
                "createdAt": .string(user.createdAt)
            ]
        )
    }

    func updateDisplayName(_ userId: String, name: String) async throws {
        try await db.updateDocument(
            collection: "users",
            documentId: userId,
            fields: ["displayName": .string(name)]
        )
    }
}
