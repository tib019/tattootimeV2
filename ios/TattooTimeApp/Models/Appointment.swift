import Foundation

enum AppointmentStatus: String, Codable, CaseIterable {
    case angefragt, bestaetigt, abgeschlossen, storniert

    var displayName: String {
        switch self {
        case .angefragt: return "Angefragt"
        case .bestaetigt: return "Bestätigt"
        case .abgeschlossen: return "Abgeschlossen"
        case .storniert: return "Storniert"
        }
    }
}

enum BodyPart: String, Codable, CaseIterable {
    case arm, leg, back, chest, ribs, neck, face, hand, foot

    var displayName: String { rawValue.capitalized }

    var multiplier: Double {
        switch self {
        case .arm, .leg: return 1.0
        case .back: return 1.3
        case .chest: return 1.2
        case .ribs: return 1.5
        case .neck: return 1.4
        case .face: return 2.0
        case .hand, .foot: return 1.3
        }
    }
}

enum TattooStyle: String, Codable, CaseIterable {
    case traditional, realistic, watercolor, geometric, minimalist, japanese, tribal, lettering

    var displayName: String {
        rawValue == "japanese" ? "Japanese" : rawValue.capitalized
    }

    var multiplier: Double {
        switch self {
        case .realistic: return 1.4
        case .watercolor: return 1.3
        case .japanese: return 1.2
        case .geometric: return 1.1
        case .traditional, .tribal: return 1.0
        case .minimalist: return 0.9
        case .lettering: return 0.8
        }
    }
}

enum Complexity: String, Codable, CaseIterable {
    case simple, medium, complex, very_complex

    var displayName: String {
        switch self {
        case .simple: return "Einfach"
        case .medium: return "Mittel"
        case .complex: return "Komplex"
        case .very_complex: return "Sehr komplex"
        }
    }

    var multiplier: Double {
        switch self {
        case .simple: return 0.9
        case .medium: return 1.0
        case .complex: return 1.3
        case .very_complex: return 1.6
        }
    }
}

struct Appointment: Codable, Identifiable {
    var id: String
    var date: String            // "YYYY-MM-DD"
    var startTime: String
    var clientName: String
    var clientEmail: String
    var service: String
    var userId: String
    var status: AppointmentStatus
    var bodyPart: BodyPart?
    var tattooStyle: TattooStyle?
    var sizeWidth: Double
    var sizeHeight: Double
    var complexity: Complexity?
    var estimatedDuration: Int  // minutes
    var colors: [String]
    var notes: String
    var totalPrice: Double?
    var depositAmount: Double?
    var depositPaid: Bool
    var slotId: String
    var createdAt: String

    init(id: String = UUID().uuidString,
         date: String, startTime: String,
         clientName: String, clientEmail: String,
         service: String = "Tattoo",
         userId: String,
         status: AppointmentStatus = .angefragt,
         slotId: String) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.clientName = clientName
        self.clientEmail = clientEmail
        self.service = service
        self.userId = userId
        self.status = status
        self.slotId = slotId
        self.sizeWidth = 0
        self.sizeHeight = 0
        self.estimatedDuration = 60
        self.colors = []
        self.notes = ""
        self.depositPaid = false
        self.createdAt = ISO8601DateFormatter().string(from: Date())
    }

    var sizeArea: Double { sizeWidth * sizeHeight }

    var formattedPrice: String {
        guard let price = totalPrice else { return "–" }
        return String(format: "%.2f €", price)
    }

    var formattedDeposit: String {
        guard let deposit = depositAmount else { return "–" }
        return String(format: "%.2f €", deposit)
    }
}
