import Foundation

// MARK: - Firestore field value encoding/decoding

enum FSValue {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([FSValue])
    case map([String: FSValue])

    // Encode to Firestore REST format
    var encoded: [String: Any] {
        switch self {
        case .string(let v): return ["stringValue": v]
        case .int(let v):    return ["integerValue": "\(v)"]
        case .double(let v): return ["doubleValue": v]
        case .bool(let v):   return ["booleanValue": v]
        case .null:          return ["nullValue": NSNull()]
        case .array(let arr):
            return ["arrayValue": ["values": arr.map { $0.encoded }]]
        case .map(let dict):
            return ["mapValue": ["fields": dict.mapValues { $0.encoded }]]
        }
    }

    // Decode from Firestore REST format
    static func decode(_ raw: [String: Any]) -> FSValue {
        if let v = raw["stringValue"] as? String  { return .string(v) }
        if let v = raw["integerValue"] as? String { return .int(Int(v) ?? 0) }
        if let v = raw["doubleValue"]             { return .double((v as AnyObject).doubleValue ?? 0) }
        if let v = raw["booleanValue"] as? Bool   { return .bool(v) }
        if raw["nullValue"] != nil                { return .null }
        if let arr = (raw["arrayValue"] as? [String: Any])?["values"] as? [[String: Any]] {
            return .array(arr.map { decode($0) })
        }
        if let fields = (raw["mapValue"] as? [String: Any])?["fields"] as? [String: [String: Any]] {
            return .map(fields.mapValues { decode($0) })
        }
        return .null
    }

    var stringValue: String? { if case .string(let v) = self { return v }; return nil }
    var intValue: Int?       { if case .int(let v)    = self { return v }; return nil }
    var doubleValue: Double? { if case .double(let v) = self { return v }; return nil }
    var boolValue: Bool?     { if case .bool(let v)   = self { return v }; return nil }
    var arrayValue: [FSValue]? { if case .array(let v) = self { return v }; return nil }
    var mapValue: [String: FSValue]? { if case .map(let v) = self { return v }; return nil }
}

typealias FSDoc = [String: FSValue]

// MARK: - FirestoreService

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    // MARK: Get single document

    func getDocument(collection: String, documentId: String) async throws -> (id: String, fields: FSDoc) {
        let url = URL(string: "\(FirebaseConfig.firestoreURL)/\(collection)/\(documentId)")!
        let data = try await get(url: url)
        return try parseDocument(data)
    }

    // MARK: List documents (optionally with simple equality filter)

    func listDocuments(collection: String) async throws -> [(id: String, fields: FSDoc)] {
        let url = URL(string: "\(FirebaseConfig.firestoreURL)/\(collection)")!
        let data = try await get(url: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let docs = json["documents"] as? [[String: Any]] else {
            return []
        }

        return try docs.map { try parseDocument(JSONSerialization.data(withJSONObject: $0)) }
    }

    // MARK: Run structured query (equality filters)

    func query(collection: String, filters: [(field: String, value: FSValue)]) async throws -> [(id: String, fields: FSDoc)] {
        let baseURL = FirebaseConfig.firestoreURL
        // Remove trailing /collection – query runs at DB level
        let dbURL = baseURL.replacingOccurrences(of: "/documents", with: "")
        let url = URL(string: "\(dbURL)/documents:runQuery")!

        var conditions: [[String: Any]] = filters.map { f in
            ["fieldFilter": [
                "field": ["fieldPath": f.field],
                "op": "EQUAL",
                "value": f.value.encoded
            ]]
        }

        let body: [String: Any] = [
            "structuredQuery": [
                "from": [["collectionId": collection]],
                "where": conditions.count == 1
                    ? conditions[0]
                    : ["compositeFilter": ["op": "AND", "filters": conditions]]
            ]
        ]

        let token = await FirebaseAuthService.shared.idToken ?? ""
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let results = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }

        return try results.compactMap { result -> (id: String, fields: FSDoc)? in
            guard let doc = result["document"] as? [String: Any] else { return nil }
            return try parseDocument(JSONSerialization.data(withJSONObject: doc))
        }
    }

    // MARK: Create / Upsert document

    func setDocument(collection: String, documentId: String, fields: FSDoc) async throws {
        let url = URL(string: "\(FirebaseConfig.firestoreURL)/\(collection)/\(documentId)")!
        let body: [String: Any] = ["fields": fields.mapValues { $0.encoded }]
        try await patch(url: url, body: body)
    }

    // MARK: Update specific fields

    func updateDocument(collection: String, documentId: String, fields: FSDoc) async throws {
        let fieldPaths = fields.keys.joined(separator: ",")
        var components = URLComponents(string: "\(FirebaseConfig.firestoreURL)/\(collection)/\(documentId)")!
        components.queryItems = fields.keys.map { URLQueryItem(name: "updateMask.fieldPaths", value: $0) }
        let url = components.url!
        let body: [String: Any] = ["fields": fields.mapValues { $0.encoded }]
        try await patch(url: url, body: body)
    }

    // MARK: Delete document

    func deleteDocument(collection: String, documentId: String) async throws {
        let url = URL(string: "\(FirebaseConfig.firestoreURL)/\(collection)/\(documentId)")!
        let token = await FirebaseAuthService.shared.idToken ?? ""
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw AppError.httpError(http.statusCode)
        }
    }

    // MARK: Private helpers

    private func get(url: URL) async throws -> Data {
        let token = await FirebaseAuthService.shared.idToken ?? ""
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw AppError.httpError(http.statusCode)
        }
        return data
    }

    private func patch(url: URL, body: [String: Any]) async throws {
        let token = await FirebaseAuthService.shared.idToken ?? ""
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw AppError.httpError(http.statusCode)
        }
    }

    private func parseDocument(_ data: Data) throws -> (id: String, fields: FSDoc) {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.decode("Invalid JSON")
        }
        let name = json["name"] as? String ?? ""
        let docId = name.components(separatedBy: "/").last ?? UUID().uuidString
        let rawFields = json["fields"] as? [String: [String: Any]] ?? [:]
        let fields: FSDoc = rawFields.mapValues { FSValue.decode($0) }
        return (docId, fields)
    }
}
