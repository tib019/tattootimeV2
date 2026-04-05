import SwiftUI

struct BookingView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = BookingViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ttBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Step indicator
                    StepIndicator(current: vm.currentStep.rawValue,
                                  total: BookingViewModel.Step.allCases.count)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    Text(vm.currentStep.title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.top, 12)

                    // Step content
                    ScrollView {
                        VStack(spacing: 0) {
                            switch vm.currentStep {
                            case .datePicker:   DatePickerStep(vm: vm)
                            case .slotPicker:   SlotPickerStep(vm: vm)
                            case .details:      DetailsStep(vm: vm)
                            case .pricing:      PricingStep(vm: vm)
                            case .confirmation: ConfirmationStep(vm: vm)
                            }
                        }
                        .padding()
                    }

                    // Navigation buttons
                    HStack(spacing: 12) {
                        if vm.currentStep.rawValue > 0 {
                            Button("Zurück") {
                                withAnimation {
                                    vm.currentStep = BookingViewModel.Step(rawValue: vm.currentStep.rawValue - 1)!
                                }
                            }
                            .foregroundColor(.ttMuted)
                            .frame(width: 80, height: 50)
                            .background(Color.ttCard)
                            .cornerRadius(12)
                        }

                        if vm.currentStep == .confirmation {
                            Button {
                                Task {
                                    guard let uid = auth.currentUser?.id else { return }
                                    await vm.confirmBooking(userId: uid)
                                }
                            } label: {
                                if vm.isLoading {
                                    ProgressView().tint(.black)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                } else {
                                    Text("Jetzt buchen")
                                        .font(.headline).foregroundColor(.black)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                }
                            }
                            .background(Color.ttGold)
                            .cornerRadius(12)
                            .disabled(vm.isLoading)
                        } else {
                            Button("Weiter") {
                                advanceStep()
                            }
                            .font(.headline).foregroundColor(.black)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(canAdvance ? Color.ttGold : Color.ttCard)
                            .cornerRadius(12)
                            .disabled(!canAdvance)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Termin buchen")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.ttGold)
                }
            }
            .alert("Fehler", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .sheet(isPresented: $vm.bookingComplete) {
                BookingSuccessView { vm.reset() }
            }
        }
    }

    private var canAdvance: Bool {
        switch vm.currentStep {
        case .datePicker:   return true
        case .slotPicker:   return vm.canAdvanceFromStep1
        case .details:      return vm.canAdvanceFromStep2
        case .pricing:      return true
        case .confirmation: return true
        }
    }

    private func advanceStep() {
        if vm.currentStep == .details { vm.calculatePrice() }
        if vm.currentStep == .datePicker {
            Task { await vm.loadSlots() }
        }
        withAnimation {
            vm.currentStep = BookingViewModel.Step(rawValue: vm.currentStep.rawValue + 1)!
        }
    }
}

// MARK: - Step Indicator

private struct StepIndicator: View {
    let current: Int
    let total: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i <= current ? Color.ttGold : Color.ttCard)
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Step 0: Date Picker

private struct DatePickerStep: View {
    @ObservedObject var vm: BookingViewModel
    var body: some View {
        VStack(spacing: 20) {
            DatePicker("Datum", selection: $vm.selectedDate,
                       in: Date()...,
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .accentColor(.ttGold)
                .colorScheme(.dark)
                .padding()
                .background(Color.ttCard)
                .cornerRadius(14)
        }
    }
}

// MARK: - Step 1: Slot Picker

private struct SlotPickerStep: View {
    @ObservedObject var vm: BookingViewModel
    var body: some View {
        VStack(spacing: 16) {
            if vm.isLoading {
                ProgressView().tint(.ttGold).padding(40)
            } else if vm.availableSlots.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40)).foregroundColor(.ttMuted)
                    Text("Keine freien Termine an diesem Tag.")
                        .foregroundColor(.ttMuted)
                }
                .padding(40)
            } else {
                ForEach(vm.availableSlots) { slot in
                    SlotCell(slot: slot, isSelected: vm.selectedSlot?.id == slot.id) {
                        vm.selectedSlot = slot
                    }
                }
            }
        }
    }
}

private struct SlotCell: View {
    let slot: Slot
    let isSelected: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(isSelected ? .black : .ttGold)
                Text(slot.displayTime)
                    .font(.headline)
                    .foregroundColor(isSelected ? .black : .white)
                Spacer()
                Text(slot.displayDuration)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : .ttMuted)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                }
            }
            .padding(16)
            .background(isSelected ? Color.ttGold : Color.ttCard)
            .cornerRadius(12)
        }
    }
}

// MARK: - Step 2: Details

private struct DetailsStep: View {
    @ObservedObject var vm: BookingViewModel
    private let colors = ["Schwarz", "Grau", "Rot", "Blau", "Grün", "Gelb",
                          "Orange", "Lila", "Rosa", "Weiß"]

    var body: some View {
        VStack(spacing: 20) {
            // Contact
            TTCard {
                VStack(spacing: 14) {
                    SectionHeader(title: "Kontakt")
                    TTTextField(placeholder: "Dein Name", text: $vm.clientName, icon: "person")
                    TTTextField(placeholder: "E-Mail", text: $vm.clientEmail, icon: "envelope")
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }

            // Tattoo details
            TTCard {
                VStack(spacing: 14) {
                    SectionHeader(title: "Tattoo")

                    TTPickerRow(label: "Körperstelle", selection: $vm.bodyPart,
                                options: BodyPart.allCases, display: \.displayName)

                    TTPickerRow(label: "Stil", selection: $vm.tattooStyle,
                                options: TattooStyle.allCases, display: \.displayName)

                    TTPickerRow(label: "Komplexität", selection: $vm.complexity,
                                options: Complexity.allCases, display: \.displayName)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Breite: \(Int(vm.sizeWidth)) cm")
                            .font(.caption).foregroundColor(.ttMuted)
                        Slider(value: $vm.sizeWidth, in: 1...50, step: 1)
                            .accentColor(.ttGold)
                        Text("Höhe: \(Int(vm.sizeHeight)) cm")
                            .font(.caption).foregroundColor(.ttMuted)
                        Slider(value: $vm.sizeHeight, in: 1...50, step: 1)
                            .accentColor(.ttGold)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dauer: \(Int(vm.estimatedDuration)) min")
                            .font(.caption).foregroundColor(.ttMuted)
                        Slider(value: $vm.estimatedDuration, in: 30...480, step: 30)
                            .accentColor(.ttGold)
                    }
                }
            }

            // Colors
            TTCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Farben")
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 8) {
                        ForEach(colors, id: \.self) { color in
                            ColorChip(name: color, selected: vm.selectedColors.contains(color)) {
                                if vm.selectedColors.contains(color) {
                                    vm.selectedColors.remove(color)
                                } else {
                                    vm.selectedColors.insert(color)
                                }
                            }
                        }
                    }
                }
            }

            // Notes
            TTCard {
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Anmerkungen")
                    TextEditor(text: $vm.notes)
                        .frame(height: 80)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

private struct TTPickerRow<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let options: [T]
    let display: (T) -> String

    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.ttMuted)
            Spacer()
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { opt in
                    Text(display(opt)).tag(opt)
                }
            }
            .pickerStyle(.menu)
            .accentColor(.ttGold)
        }
    }
}

private struct ColorChip: View {
    let name: String
    let selected: Bool
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.caption.weight(selected ? .semibold : .regular))
                .foregroundColor(selected ? .black : .ttMuted)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(selected ? Color.ttGold : Color.ttSurface)
                .cornerRadius(8)
        }
    }
}

// MARK: - Step 3: Pricing

private struct PricingStep: View {
    @ObservedObject var vm: BookingViewModel
    var body: some View {
        TTCard {
            VStack(spacing: 16) {
                Image(systemName: "eurosign.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.ttGold)

                Text("Preisschätzung")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)

                Divider().background(Color.ttSurface)

                PriceRow(label: "Körperstelle (\(vm.bodyPart.displayName))",
                         value: "×\(String(format: "%.1f", vm.bodyPart.multiplier))")
                PriceRow(label: "Stil (\(vm.tattooStyle.displayName))",
                         value: "×\(String(format: "%.1f", vm.tattooStyle.multiplier))")
                PriceRow(label: "Komplexität (\(vm.complexity.displayName))",
                         value: "×\(String(format: "%.1f", vm.complexity.multiplier))")
                PriceRow(label: "Fläche (\(Int(vm.sizeWidth))×\(Int(vm.sizeHeight)) cm)",
                         value: "\(Int(vm.sizeWidth * vm.sizeHeight)) cm²")
                PriceRow(label: "Dauer", value: "\(Int(vm.estimatedDuration)) min")

                Divider().background(Color.ttSurface)

                HStack {
                    Text("Gesamtpreis").font(.headline).foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.2f €", vm.calculatedTotal))
                        .font(.title2.weight(.bold)).foregroundColor(.ttGold)
                }
                HStack {
                    Text("Anzahlung (30%)").font(.subheadline).foregroundColor(.ttMuted)
                    Spacer()
                    Text(String(format: "%.2f €", vm.calculatedDeposit))
                        .font(.subheadline.weight(.semibold)).foregroundColor(.ttGold)
                }
            }
        }
    }
}

private struct PriceRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.ttMuted)
            Spacer()
            Text(value).font(.subheadline).foregroundColor(.white)
        }
    }
}

// MARK: - Step 4: Confirmation

private struct ConfirmationStep: View {
    @ObservedObject var vm: BookingViewModel
    var body: some View {
        VStack(spacing: 16) {
            TTCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Buchungsübersicht")
                    ConfirmRow(label: "Datum",    value: vm.selectedDateString.displayDate)
                    ConfirmRow(label: "Uhrzeit",  value: vm.selectedSlot?.displayTime ?? "–")
                    ConfirmRow(label: "Name",     value: vm.clientName)
                    ConfirmRow(label: "E-Mail",   value: vm.clientEmail)
                    ConfirmRow(label: "Körperstelle", value: vm.bodyPart.displayName)
                    ConfirmRow(label: "Stil",     value: vm.tattooStyle.displayName)
                    ConfirmRow(label: "Fläche",   value: "\(Int(vm.sizeWidth))×\(Int(vm.sizeHeight)) cm")
                    ConfirmRow(label: "Dauer",    value: "\(Int(vm.estimatedDuration)) min")
                    Divider().background(Color.ttSurface)
                    ConfirmRow(label: "Preis",    value: String(format: "%.2f €", vm.calculatedTotal))
                    ConfirmRow(label: "Anzahlung", value: String(format: "%.2f €", vm.calculatedDeposit))
                }
            }

            Text("Nach der Buchung erhältst du eine Bestätigungs-E-Mail.")
                .font(.caption).foregroundColor(.ttMuted)
                .multilineTextAlignment(.center)
        }
    }
}

private struct ConfirmRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.ttMuted)
            Spacer()
            Text(value).font(.subheadline.weight(.medium)).foregroundColor(.white)
        }
    }
}

// MARK: - Success sheet

struct BookingSuccessView: View {
    let onDismiss: () -> Void
    var body: some View {
        ZStack {
            Color.ttBackground.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.ttGold)
                Text("Termin gebucht!")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Wir werden deinen Termin bald bestätigen.\nSchau in deinen E-Mails nach.")
                    .font(.subheadline).foregroundColor(.ttMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button("Fertig") { onDismiss() }
                    .font(.headline).foregroundColor(.black)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.ttGold)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
    }
}
