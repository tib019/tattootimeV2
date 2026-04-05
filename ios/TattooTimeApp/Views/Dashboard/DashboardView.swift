import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = AppointmentViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ttBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Hero header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hallo, \(auth.currentUser?.displayName ?? "")!")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                Text(Date().shortFormatted)
                                    .font(.subheadline)
                                    .foregroundColor(.ttMuted)
                            }
                            Spacer()
                            Image(systemName: "pencil.tip.crop.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.ttGold)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Next appointment banner
                        if let next = vm.upcoming.first {
                            NextAppointmentBanner(appointment: next)
                                .padding(.horizontal)
                        } else if !vm.isLoading {
                            EmptyAppointmentBanner()
                                .padding(.horizontal)
                        }

                        // Upcoming count tiles
                        HStack(spacing: 12) {
                            StatTile(
                                value: "\(vm.upcoming.count)",
                                label: "Ausstehend",
                                icon: "clock.fill",
                                color: .ttGold
                            )
                            StatTile(
                                value: "\(vm.past.filter { $0.status == .abgeschlossen }.count)",
                                label: "Abgeschlossen",
                                icon: "checkmark.seal.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)

                        // Recent appointments list
                        if !vm.appointments.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Letzte Termine")
                                    .padding(.horizontal)

                                ForEach(vm.appointments.prefix(5)) { appt in
                                    AppointmentRow(appointment: appt)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("TattooTime")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.ttGold)
                }
            }
            .task {
                guard let uid = auth.currentUser?.id else { return }
                await vm.loadMyAppointments(userId: uid)
            }
        }
    }
}

// MARK: - Sub-views

private struct NextAppointmentBanner: View {
    let appointment: Appointment
    var body: some View {
        TTCard {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.ttGold)
                    .frame(width: 4, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Nächster Termin")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.ttGold)
                    Text(appointment.date.displayDate)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("\(appointment.startTime)  ·  \(appointment.service)")
                        .font(.subheadline)
                        .foregroundColor(.ttMuted)
                }
                Spacer()
                StatusBadge(status: appointment.status)
            }
        }
    }
}

private struct EmptyAppointmentBanner: View {
    var body: some View {
        TTCard {
            HStack(spacing: 14) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 28))
                    .foregroundColor(.ttGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Noch keine Termine")
                        .font(.headline).foregroundColor(.white)
                    Text("Jetzt ersten Termin buchen")
                        .font(.caption).foregroundColor(.ttMuted)
                }
                Spacer()
            }
        }
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        TTCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.ttMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct AppointmentRow: View {
    let appointment: Appointment
    var body: some View {
        TTCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.date.displayDate)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                    Text("\(appointment.startTime)  ·  \(appointment.bodyPart?.displayName ?? appointment.service)")
                        .font(.caption)
                        .foregroundColor(.ttMuted)
                    if let price = appointment.totalPrice {
                        Text(String(format: "%.2f €", price))
                            .font(.caption.weight(.medium))
                            .foregroundColor(.ttGold)
                    }
                }
                Spacer()
                StatusBadge(status: appointment.status)
            }
        }
    }
}
