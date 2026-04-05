import Foundation

@MainActor
final class AdminViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var slots: [Slot] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Calendar date selection

    @Published var selectedDate: Date = Date()
    var selectedDateString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: selectedDate)
    }

    // MARK: - New slot form

    @Published var newSlotDate: Date = Date()
    @Published var newSlotStart = "10:00"
    @Published var newSlotEnd   = "11:00"
    @Published var newSlotDuration: Int = 60

    // MARK: - Load all appointments

    func loadAllAppointments() async {
        isLoading = true
        defer { isLoading = false }
        do {
            appointments = try await AppointmentService.shared.getAllAppointments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load appointments for selected date

    func loadAppointmentsForSelectedDate() async {
        isLoading = true
        defer { isLoading = false }
        do {
            appointments = try await AppointmentService.shared.getAppointments(for: selectedDateString)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update status

    func updateStatus(id: String, status: AppointmentStatus) async {
        do {
            try await AppointmentService.shared.updateStatus(id, status: status)
            if let idx = appointments.firstIndex(where: { $0.id == id }) {
                appointments[idx].status = status
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete appointment

    func deleteAppointment(id: String) async {
        do {
            try await AppointmentService.shared.delete(id)
            appointments.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load all slots

    func loadAllSlots() async {
        isLoading = true
        defer { isLoading = false }
        do {
            slots = try await SlotService.shared.getAllSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Create slot

    func createSlot() async {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        let slot = Slot(
            date: f.string(from: newSlotDate),
            startTime: newSlotStart,
            endTime: newSlotEnd,
            duration: newSlotDuration
        )
        do {
            try await SlotService.shared.create(slot)
            slots.append(slot)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete slot

    func deleteSlot(id: String) async {
        do {
            try await SlotService.shared.delete(id)
            slots.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Filtered slots for selected date

    var slotsForSelectedDate: [Slot] {
        slots.filter { $0.date == selectedDateString }
    }
}
