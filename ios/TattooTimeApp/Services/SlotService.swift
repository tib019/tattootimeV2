import Foundation

final class SlotService {
    static let shared = SlotService()
    private let db = FirestoreService.shared
    private init() {}

    // MARK: - Available slots for a date

    func getAvailableSlots(for date: String) async throws -> [Slot] {
        let docs = try await db.query(
            collection: "slots",
            filters: [("date", .string(date)), ("isBooked", .bool(false))]
        )
        return docs.compactMap { decode($0.id, $0.fields) }
            .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - All slots (admin)

    func getAllSlots() async throws -> [Slot] {
        let docs = try await db.listDocuments(collection: "slots")
        return docs.compactMap { decode($0.id, $0.fields) }
            .sorted { ($0.date, $0.startTime) < ($1.date, $1.startTime) }
    }

    // MARK: - Create slot (admin)

    func create(_ slot: Slot) async throws {
        try await db.setDocument(
            collection: "slots",
            documentId: slot.id,
            fields: encode(slot)
        )
    }

    // MARK: - Book slot (marks as booked)

    func book(_ slotId: String) async throws {
        try await db.updateDocument(
            collection: "slots",
            documentId: slotId,
            fields: ["isBooked": .bool(true)]
        )
    }

    // MARK: - Delete slot (admin)

    func delete(_ slotId: String) async throws {
        try await db.deleteDocument(collection: "slots", documentId: slotId)
    }

    // MARK: - Encode/Decode

    private func encode(_ s: Slot) -> FSDoc {
        [
            "date": .string(s.date),
            "startTime": .string(s.startTime),
            "endTime": .string(s.endTime),
            "duration": .int(s.duration),
            "isBooked": .bool(s.isBooked),
            "serviceType": .string(s.serviceType)
        ]
    }

    private func decode(_ id: String, _ f: FSDoc) -> Slot? {
        guard
            let date      = f["date"]?.stringValue,
            let startTime = f["startTime"]?.stringValue,
            let endTime   = f["endTime"]?.stringValue
        else { return nil }

        return Slot(
            id: id,
            date: date,
            startTime: startTime,
            endTime: endTime,
            duration: f["duration"]?.intValue ?? 60,
            serviceType: f["serviceType"]?.stringValue ?? "Tattoo"
        )
    }
}
