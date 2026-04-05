import SwiftUI

struct AdminSlotsView: View {
    @StateObject private var vm = AdminViewModel()
    @State private var showAddSheet = false

    var body: some View {
        ZStack {
            Color.ttBackground.ignoresSafeArea()

            Group {
                if vm.isLoading {
                    ProgressView().tint(.ttGold)
                } else if vm.slots.isEmpty {
                    EmptyState(icon: "clock.badge.plus",
                               title: "Keine Slots",
                               subtitle: "Erstelle den ersten Zeitslot für dein Studio.")
                } else {
                    ScrollView {
                        // Group by date
                        let grouped = Dictionary(grouping: vm.slots) { $0.date }
                        let sortedKeys = grouped.keys.sorted()

                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(sortedKeys, id: \.self) { date in
                                VStack(alignment: .leading, spacing: 8) {
                                    SectionHeader(title: date.displayDate)
                                        .padding(.horizontal)
                                    ForEach(grouped[date] ?? []) { slot in
                                        SlotRow(slot: slot) {
                                            Task { await vm.deleteSlot(id: slot.id) }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .navigationTitle("Slots verwalten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.ttGold)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddSlotSheet(vm: vm, isPresented: $showAddSheet)
        }
        .task { await vm.loadAllSlots() }
    }
}

// MARK: - Slot row

private struct SlotRow: View {
    let slot: Slot
    let onDelete: () -> Void
    @State private var showConfirm = false

    var body: some View {
        TTCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(slot.displayTime)
                        .font(.headline).foregroundColor(.white)
                    HStack(spacing: 8) {
                        Text(slot.displayDuration)
                            .font(.caption).foregroundColor(.ttMuted)
                        Text("·")
                            .foregroundColor(.ttMuted)
                        Text(slot.serviceType)
                            .font(.caption).foregroundColor(.ttMuted)
                    }
                }
                Spacer()
                if slot.isBooked {
                    Label("Gebucht", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.green)
                } else {
                    Label("Frei", systemImage: "circle.dashed")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.ttGold)
                }
                Button {
                    showConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(.leading, 8)
                }
            }
        }
        .alert("Slot löschen?", isPresented: $showConfirm) {
            Button("Löschen", role: .destructive) { onDelete() }
            Button("Abbrechen", role: .cancel) {}
        }
    }
}

// MARK: - Add slot sheet

private struct AddSlotSheet: View {
    @ObservedObject var vm: AdminViewModel
    @Binding var isPresented: Bool

    private let timeOptions = stride(from: 8, through: 20, by: 0.5).map { h -> String in
        let hour = Int(h)
        let min  = h.truncatingRemainder(dividingBy: 1) == 0 ? "00" : "30"
        return String(format: "%02d:%@", hour, min)
    }

    private let durationOptions = [30, 60, 90, 120, 180, 240, 300, 360, 420, 480]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ttBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        TTCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Datum")
                                DatePicker("", selection: $vm.newSlotDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .accentColor(.ttGold)
                            }
                        }

                        TTCard {
                            VStack(alignment: .leading, spacing: 14) {
                                SectionHeader(title: "Uhrzeit")
                                HStack {
                                    Text("Von").font(.subheadline).foregroundColor(.ttMuted)
                                    Spacer()
                                    Picker("Von", selection: $vm.newSlotStart) {
                                        ForEach(timeOptions, id: \.self) { t in
                                            Text(t).tag(t)
                                        }
                                    }
                                    .pickerStyle(.menu).accentColor(.ttGold)
                                }
                                HStack {
                                    Text("Bis").font(.subheadline).foregroundColor(.ttMuted)
                                    Spacer()
                                    Picker("Bis", selection: $vm.newSlotEnd) {
                                        ForEach(timeOptions, id: \.self) { t in
                                            Text(t).tag(t)
                                        }
                                    }
                                    .pickerStyle(.menu).accentColor(.ttGold)
                                }
                                HStack {
                                    Text("Dauer").font(.subheadline).foregroundColor(.ttMuted)
                                    Spacer()
                                    Picker("Dauer", selection: $vm.newSlotDuration) {
                                        ForEach(durationOptions, id: \.self) { d in
                                            Text("\(d) min").tag(d)
                                        }
                                    }
                                    .pickerStyle(.menu).accentColor(.ttGold)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Slot erstellen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { isPresented = false }
                        .foregroundColor(.ttMuted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Erstellen") {
                        Task {
                            await vm.createSlot()
                            isPresented = false
                        }
                    }
                    .foregroundColor(.ttGold)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
