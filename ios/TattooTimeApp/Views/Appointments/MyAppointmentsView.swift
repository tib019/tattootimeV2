import SwiftUI

struct MyAppointmentsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = AppointmentViewModel()
    @State private var showCancelConfirm: Appointment?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ttBackground.ignoresSafeArea()

                Group {
                    if vm.isLoading {
                        ProgressView().tint(.ttGold)
                    } else if vm.appointments.isEmpty {
                        EmptyState(
                            icon: "calendar",
                            title: "Keine Termine",
                            subtitle: "Buche deinen ersten Termin über den Tab „Buchen"."
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if !vm.upcoming.isEmpty {
                                    SectionHeader(title: "Bevorstehend")
                                        .padding(.horizontal)
                                    ForEach(vm.upcoming) { appt in
                                        AppointmentDetailCard(appointment: appt) {
                                            showCancelConfirm = appt
                                        }
                                        .padding(.horizontal)
                                    }
                                }

                                if !vm.past.isEmpty {
                                    SectionHeader(title: "Vergangen")
                                        .padding(.horizontal)
                                        .padding(.top, 8)
                                    ForEach(vm.past) { appt in
                                        AppointmentDetailCard(appointment: appt, canCancel: false)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Meine Termine")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.ttGold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await reload() } } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.ttGold)
                    }
                }
            }
            .alert("Termin absagen?", isPresented: .constant(showCancelConfirm != nil)) {
                Button("Absagen", role: .destructive) {
                    guard let appt = showCancelConfirm else { return }
                    Task { await vm.cancel(id: appt.id) }
                    showCancelConfirm = nil
                }
                Button("Abbrechen", role: .cancel) { showCancelConfirm = nil }
            } message: {
                Text("Dieser Termin wird als storniert markiert.")
            }
            .task { await reload() }
        }
    }

    private func reload() async {
        guard let uid = auth.currentUser?.id else { return }
        await vm.loadMyAppointments(userId: uid)
    }
}

// MARK: - Detail card

struct AppointmentDetailCard: View {
    let appointment: Appointment
    var canCancel = true
    var onCancel: (() -> Void)? = nil

    var body: some View {
        TTCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appointment.date.displayDate)
                            .font(.headline).foregroundColor(.white)
                        Text(appointment.startTime)
                            .font(.subheadline).foregroundColor(.ttMuted)
                    }
                    Spacer()
                    StatusBadge(status: appointment.status)
                }

                if let bp = appointment.bodyPart, let style = appointment.tattooStyle {
                    HStack(spacing: 16) {
                        Label(bp.displayName, systemImage: "person.fill")
                        Label(style.displayName, systemImage: "paintbrush.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.ttMuted)
                }

                if appointment.sizeWidth > 0 {
                    HStack(spacing: 16) {
                        Label("\(Int(appointment.sizeWidth))×\(Int(appointment.sizeHeight)) cm",
                              systemImage: "ruler")
                        Label("\(appointment.estimatedDuration) min",
                              systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.ttMuted)
                }

                if let price = appointment.totalPrice {
                    Divider().background(Color.ttSurface)
                    HStack {
                        Text("Preis")
                            .font(.caption).foregroundColor(.ttMuted)
                        Spacer()
                        Text(String(format: "%.2f €", price))
                            .font(.subheadline.weight(.semibold)).foregroundColor(.ttGold)
                        if let deposit = appointment.depositAmount {
                            Text("(Anzahlung: \(String(format: "%.2f €", deposit)))")
                                .font(.caption2).foregroundColor(.ttMuted)
                        }
                    }
                }

                if canCancel,
                   appointment.status == .angefragt || appointment.status == .bestaetigt,
                   let cancel = onCancel {
                    Button(action: cancel) {
                        Label("Absagen", systemImage: "xmark.circle")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.red)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Empty state

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 52))
                .foregroundColor(.ttMuted)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.ttMuted)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
