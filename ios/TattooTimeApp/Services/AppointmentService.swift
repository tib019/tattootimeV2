import Foundation

final class AppointmentService {
    static let shared = AppointmentService()
    private let db = FirestoreService.shared
    private init() {}

    // MARK: - Fetch all appointments (admin)

    func getAllAppointments() async throws -> [Appointment] {
        let docs = try await db.listDocuments(collection: "appointments")
        return docs.compactMap { decode($0.id, $0.fields) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Fetch appointments for a user

    func getAppointments(for userId: String) async throws -> [Appointment] {
        let docs = try await db.query(
            collection: "appointments",
            filters: [("userId", .string(userId))]
        )
        return docs.compactMap { decode($0.id, $0.fields) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Fetch appointments for a date (admin)

    func getAppointments(for date: String) async throws -> [Appointment] {
        let docs = try await db.query(
            collection: "appointments",
            filters: [("date", .string(date))]
        )
        return docs.compactMap { decode($0.id, $0.fields) }
            .sorted { $0.startTime < $1.startTime }
    }

    // MARK: - Create appointment

    func create(_ appointment: Appointment) async throws {
        try await db.setDocument(
            collection: "appointments",
            documentId: appointment.id,
            fields: encode(appointment)
        )
    }

    // MARK: - Update status

    func updateStatus(_ id: String, status: AppointmentStatus) async throws {
        try await db.updateDocument(
            collection: "appointments",
            documentId: id,
            fields: ["status": .string(status.rawValue)]
        )
    }

    // MARK: - Cancel appointment

    func cancel(_ id: String) async throws {
        try await updateStatus(id, status: .storniert)
    }

    // MARK: - Delete appointment

    func delete(_ id: String) async throws {
        try await db.deleteDocument(collection: "appointments", documentId: id)
    }

    // MARK: - Encode/Decode helpers

    private func encode(_ a: Appointment) -> FSDoc {
        var fields: FSDoc = [
            "date": .string(a.date),
            "startTime": .string(a.startTime),
            "clientName": .string(a.clientName),
            "clientEmail": .string(a.clientEmail),
            "service": .string(a.service),
            "userId": .string(a.userId),
            "status": .string(a.status.rawValue),
            "sizeWidth": .double(a.sizeWidth),
            "sizeHeight": .double(a.sizeHeight),
            "estimatedDuration": .int(a.estimatedDuration),
            "colors": .array(a.colors.map { .string($0) }),
            "notes": .string(a.notes),
            "depositPaid": .bool(a.depositPaid),
            "slotId": .string(a.slotId),
            "createdAt": .string(a.createdAt)
        ]
        if let bp = a.bodyPart         { fields["bodyPart"] = .string(bp.rawValue) }
        if let ts = a.tattooStyle      { fields["tattooStyle"] = .string(ts.rawValue) }
        if let cx = a.complexity       { fields["complexity"] = .string(cx.rawValue) }
        if let tp = a.totalPrice       { fields["totalPrice"] = .double(tp) }
        if let da = a.depositAmount    { fields["depositAmount"] = .double(da) }
        return fields
    }

    private func decode(_ id: String, _ f: FSDoc) -> Appointment? {
        guard
            let date       = f["date"]?.stringValue,
            let startTime  = f["startTime"]?.stringValue,
            let clientName = f["clientName"]?.stringValue,
            let clientEmail = f["clientEmail"]?.stringValue,
            let userId     = f["userId"]?.stringValue,
            let statusRaw  = f["status"]?.stringValue,
            let status     = AppointmentStatus(rawValue: statusRaw),
            let slotId     = f["slotId"]?.stringValue
        else { return nil }

        var a = Appointment(
            id: id, date: date, startTime: startTime,
            clientName: clientName, clientEmail: clientEmail,
            userId: userId, status: status, slotId: slotId
        )
        a.service           = f["service"]?.stringValue ?? "Tattoo"
        a.sizeWidth         = f["sizeWidth"]?.doubleValue ?? 0
        a.sizeHeight        = f["sizeHeight"]?.doubleValue ?? 0
        a.estimatedDuration = f["estimatedDuration"]?.intValue ?? 60
        a.notes             = f["notes"]?.stringValue ?? ""
        a.depositPaid       = f["depositPaid"]?.boolValue ?? false
        a.totalPrice        = f["totalPrice"]?.doubleValue
        a.depositAmount     = f["depositAmount"]?.doubleValue
        if let bp = f["bodyPart"]?.stringValue     { a.bodyPart = BodyPart(rawValue: bp) }
        if let ts = f["tattooStyle"]?.stringValue  { a.tattooStyle = TattooStyle(rawValue: ts) }
        if let cx = f["complexity"]?.stringValue   { a.complexity = Complexity(rawValue: cx) }
        a.colors = f["colors"]?.arrayValue?.compactMap { $0.stringValue } ?? []
        return a
    }
}
