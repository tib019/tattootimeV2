import SwiftUI

// MARK: - Brand Colors

extension Color {
    static let ttBackground = Color(red: 0.06, green: 0.06, blue: 0.06)
    static let ttCard       = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let ttGold       = Color(red: 0.94, green: 0.65, blue: 0.10)
    static let ttMuted      = Color(white: 0.55)
    static let ttSurface    = Color(red: 0.16, green: 0.16, blue: 0.18)
}

// MARK: - Status color

extension AppointmentStatus {
    var swiftUIColor: Color {
        switch self {
        case .angefragt:    return .orange
        case .bestaetigt:   return .green
        case .abgeschlossen: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .storniert:    return .red
        }
    }
}

// MARK: - Reusable TextField

struct TTTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = ""
    var isSecure = false

    var body: some View {
        HStack(spacing: 10) {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .foregroundColor(.ttMuted)
                    .frame(width: 20)
            }
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
        }
        .padding(14)
        .background(Color.ttCard)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ttSurface, lineWidth: 1))
    }
}

// MARK: - Gold button style

struct GoldButtonStyle: ButtonStyle {
    var isDisabled = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isDisabled ? Color.ttCard : Color.ttGold.opacity(configuration.isPressed ? 0.8 : 1))
            .cornerRadius(12)
    }
}

// MARK: - Card container

struct TTCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .padding(16)
            .background(Color.ttCard)
            .cornerRadius(14)
    }
}

// MARK: - Status badge

struct StatusBadge: View {
    let status: AppointmentStatus
    var body: some View {
        Text(status.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(status.swiftUIColor.opacity(0.18))
            .foregroundColor(status.swiftUIColor)
            .cornerRadius(6)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundColor(.ttMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Date formatter helpers

extension Date {
    var shortFormatted: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.locale = Locale(identifier: "de_DE")
        return f.string(from: self)
    }
    var firestoreString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}

extension String {
    var asDate: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: self)
    }
    var displayDate: String {
        guard let d = asDate else { return self }
        return d.shortFormatted
    }
}
