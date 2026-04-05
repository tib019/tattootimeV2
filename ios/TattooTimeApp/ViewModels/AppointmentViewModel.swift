import Foundation

@MainActor
final class AppointmentViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = AppointmentService.shared

    // MARK: - Load for logged-in user

    func loadMyAppointments(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            appointments = try await service.getAppointments(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load all (admin)

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }
        do {
            appointments = try await service.getAllAppointments()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load for a specific date (admin calendar)

    func loadForDate(_ date: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            appointments = try await service.getAppointments(for: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Cancel

    func cancel(id: String) async {
        do {
            try await service.cancel(id)
            if let idx = appointments.firstIndex(where: { $0.id == id }) {
                appointments[idx].status = .storniert
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Update status (admin)

    func updateStatus(id: String, status: AppointmentStatus) async {
        do {
            try await service.updateStatus(id, status: status)
            if let idx = appointments.firstIndex(where: { $0.id == id }) {
                appointments[idx].status = status
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Delete (admin)

    func delete(id: String) async {
        do {
            try await service.delete(id)
            appointments.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Grouped by status

    var upcoming: [Appointment] {
        appointments.filter { $0.status == .angefragt || $0.status == .bestaetigt }
    }

    var past: [Appointment] {
        appointments.filter { $0.status == .abgeschlossen || $0.status == .storniert }
    }
}
