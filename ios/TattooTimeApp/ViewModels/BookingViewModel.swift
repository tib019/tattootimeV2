import Foundation

@MainActor
final class BookingViewModel: ObservableObject {

    // MARK: Step tracking

    enum Step: Int, CaseIterable {
        case datePicker = 0, slotPicker, details, pricing, confirmation
        var title: String {
            switch self {
            case .datePicker:    return "Datum wählen"
            case .slotPicker:    return "Termin wählen"
            case .details:       return "Tattoo Details"
            case .pricing:       return "Preis"
            case .confirmation:  return "Bestätigung"
            }
        }
    }

    @Published var currentStep: Step = .datePicker
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bookingComplete = false

    // Step 0 – Date
    @Published var selectedDate: Date = Date()
    var selectedDateString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: selectedDate)
    }

    // Step 1 – Slot
    @Published var availableSlots: [Slot] = []
    @Published var selectedSlot: Slot?

    // Step 2 – Details
    @Published var clientName = ""
    @Published var clientEmail = ""
    @Published var bodyPart: BodyPart = .arm
    @Published var tattooStyle: TattooStyle = .traditional
    @Published var sizeWidth: Double = 5
    @Published var sizeHeight: Double = 5
    @Published var complexity: Complexity = .medium
    @Published var estimatedDuration: Double = 60  // minutes slider
    @Published var selectedColors: Set<String> = []
    @Published var notes = ""

    // Step 3 – Pricing
    @Published var calculatedTotal: Double = 0
    @Published var calculatedDeposit: Double = 0

    // MARK: Validation

    var canAdvanceFromStep0: Bool { true }
    var canAdvanceFromStep1: Bool { selectedSlot != nil }
    var canAdvanceFromStep2: Bool {
        !clientName.trimmingCharacters(in: .whitespaces).isEmpty &&
        clientEmail.contains("@")
    }

    // MARK: Load slots

    func loadSlots() async {
        isLoading = true
        defer { isLoading = false }
        do {
            availableSlots = try await SlotService.shared.getAvailableSlots(for: selectedDateString)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Calculate price

    func calculatePrice() {
        let area = sizeWidth * sizeHeight
        let (total, deposit) = PricingRule.shared.calculate(
            duration: Int(estimatedDuration),
            bodyPart: bodyPart,
            style: tattooStyle,
            sizeArea: area,
            complexity: complexity
        )
        calculatedTotal   = total
        calculatedDeposit = deposit
    }

    // MARK: Confirm booking

    func confirmBooking(userId: String) async {
        guard let slot = selectedSlot else { return }
        isLoading = true
        defer { isLoading = false }

        var appointment = Appointment(
            date: selectedDateString,
            startTime: slot.startTime,
            clientName: clientName,
            clientEmail: clientEmail,
            userId: userId,
            slotId: slot.id
        )
        appointment.bodyPart          = bodyPart
        appointment.tattooStyle       = tattooStyle
        appointment.sizeWidth         = sizeWidth
        appointment.sizeHeight        = sizeHeight
        appointment.complexity        = complexity
        appointment.estimatedDuration = Int(estimatedDuration)
        appointment.colors            = Array(selectedColors)
        appointment.notes             = notes
        appointment.totalPrice        = calculatedTotal
        appointment.depositAmount     = calculatedDeposit

        do {
            try await AppointmentService.shared.create(appointment)
            try await SlotService.shared.book(slot.id)
            bookingComplete = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Reset

    func reset() {
        currentStep      = .datePicker
        selectedSlot     = nil
        availableSlots   = []
        clientName       = ""
        clientEmail      = ""
        bodyPart         = .arm
        tattooStyle      = .traditional
        sizeWidth        = 5
        sizeHeight       = 5
        complexity       = .medium
        estimatedDuration = 60
        selectedColors   = []
        notes            = ""
        calculatedTotal  = 0
        calculatedDeposit = 0
        bookingComplete  = false
        errorMessage     = nil
    }
}
