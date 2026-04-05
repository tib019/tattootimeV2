import SwiftUI

struct AdminAppointmentsView: View {
    @StateObject private var vm = AdminViewModel()
    @State private var selectedFilter: AppointmentStatus? = nil

    private var filtered: [Appointment] {
        guard let f = selectedFilter else { return vm.appointments }
        return vm.appointments.filter { $0.status == f }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ttBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Date selector
                    HStack {
                        DatePicker("", selection: $vm.selectedDate, displayedComponents: .date)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .accentColor(.ttGold)
                        Spacer()
                        Button {
                            Task { await vm.loadAppointmentsForSelectedDate() }
                        } label: {
                            Label("Laden", systemImage: "arrow.clockwise")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.ttGold)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color.ttCard)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "Alle", isActive: selectedFilter == nil) {
                                selectedFilter = nil
                            }
                            ForEach(AppointmentStatus.allCases, id: \.self) { status in
                                FilterChip(label: status.displayName,
                                           isActive: selectedFilter == status,
                                           color: status.swiftUIColor) {
                                    selectedFilter = selectedFilter == status ? nil : status
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // Content
                    if vm.isLoading {
                        Spacer()
                        ProgressView().tint(.ttGold)
                        Spacer()
                    } else if filtered.isEmpty {
                        Spacer()
                        EmptyState(icon: "calendar", title: "Keine Termine",
                                   subtitle: "Für dieses Datum sind keine Termine vorhanden.")
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(filtered) { appt in
                                    AdminAppointmentCard(appointment: appt) { newStatus in
                                        Task { await vm.updateStatus(id: appt.id, status: newStatus) }
                                    } onDelete: {
                                        Task { await vm.deleteAppointment(id: appt.id) }
                                    }
                                    .padding(.horizontal)
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
                    Text("Terminverwaltung")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.ttGold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AdminSlotsView()
                    } label: {
                        Image(systemName: "clock.badge.plus")
                            .foregroundColor(.ttGold)
                    }
                }
            }
            .task { await vm.loadAllAppointments() }
        }
    }
}

// MARK: - Filter chip

private struct FilterChip: View {
    let label: String
    let isActive: Bool
    var color: Color = .ttGold
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.caption.weight(isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .black : .ttMuted)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isActive ? color : Color.ttCard)
                .cornerRadius(20)
        }
    }
}

// MARK: - Admin appointment card

private struct AdminAppointmentCard: View {
    let appointment: Appointment
    let onStatusChange: (AppointmentStatus) -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false

    var body: some View {
        TTCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appointment.clientName)
                            .font(.headline).foregroundColor(.white)
                        Text(appointment.clientEmail)
                            .font(.caption).foregroundColor(.ttMuted)
                    }
                    Spacer()
                    StatusBadge(status: appointment.status)
                }

                HStack(spacing: 16) {
                    Label(appointment.startTime, systemImage: "clock")
                    if let bp = appointment.bodyPart {
                        Label(bp.displayName, systemImage: "person")
                    }
                    if let style = appointment.tattooStyle {
                        Label(style.displayName, systemImage: "paintbrush")
                    }
                }
                .font(.caption)
                .foregroundColor(.ttMuted)

                if let price = appointment.totalPrice {
                    Text(String(format: "Preis: %.2f €  |  Anzahlung: %.2f €",
                                price, appointment.depositAmount ?? 0))
                        .font(.caption).foregroundColor(.ttGold)
                }

                if !appointment.notes.isEmpty {
                    Text(appointment.notes)
                        .font(.caption2).foregroundColor(.ttMuted)
                        .lineLimit(2)
                }

                Divider().background(Color.ttSurface)

                // Status buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AppointmentStatus.allCases, id: \.self) { status in
                            if status != appointment.status {
                                Button(status.displayName) {
                                    onStatusChange(status)
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(status.swiftUIColor)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(status.swiftUIColor.opacity(0.15))
                                .cornerRadius(8)
                            }
                        }
                        Spacer()
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .alert("Termin löschen?", isPresented: $showDeleteConfirm) {
            Button("Löschen", role: .destructive) { onDelete() }
            Button("Abbrechen", role: .cancel) {}
        }
    }
}
