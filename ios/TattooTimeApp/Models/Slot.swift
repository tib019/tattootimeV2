import Foundation

struct Slot: Codable, Identifiable {
    var id: String
    var date: String        // "YYYY-MM-DD"
    var startTime: String
    var endTime: String
    var duration: Int       // minutes
    var isBooked: Bool
    var serviceType: String

    init(id: String = UUID().uuidString,
         date: String, startTime: String, endTime: String,
         duration: Int = 60, serviceType: String = "Tattoo") {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.isBooked = false
        self.serviceType = serviceType
    }

    var displayTime: String { "\(startTime) – \(endTime)" }

    var displayDuration: String {
        duration >= 60
            ? "\(duration / 60)h\(duration % 60 > 0 ? " \(duration % 60)min" : "")"
            : "\(duration)min"
    }
}
