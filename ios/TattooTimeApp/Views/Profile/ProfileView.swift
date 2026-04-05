import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var editingName = false
    @State private var newName = ""
    @State private var showSignOutAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ttBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Avatar + name
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.ttCard)
                                    .frame(width: 90, height: 90)
                                Text(initials)
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.ttGold)
                            }
                            Text(auth.currentUser?.displayName ?? "–")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white)
                            Text(auth.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.ttMuted)
                            if auth.isAdmin {
                                Label("Administrator", systemImage: "shield.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.ttGold)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.ttGold.opacity(0.12))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top, 20)

                        // Edit name
                        TTCard {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Name ändern")
                                if editingName {
                                    TTTextField(placeholder: "Neuer Name", text: $newName, icon: "person")
                                    HStack {
                                        Button("Abbrechen") {
                                            editingName = false
                                            newName = ""
                                        }
                                        .foregroundColor(.ttMuted)
                                        Spacer()
                                        Button("Speichern") {
                                            Task { await saveName() }
                                        }
                                        .foregroundColor(.ttGold)
                                        .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                                    }
                                    .font(.subheadline.weight(.medium))
                                } else {
                                    Button {
                                        newName = auth.currentUser?.displayName ?? ""
                                        editingName = true
                                    } label: {
                                        HStack {
                                            Text("Name bearbeiten")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.ttMuted)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Account info
                        TTCard {
                            VStack(spacing: 12) {
                                SectionHeader(title: "Konto")
                                InfoRow(label: "E-Mail",
                                        value: auth.currentUser?.email ?? "–")
                                InfoRow(label: "Registriert seit",
                                        value: (auth.currentUser?.createdAt ?? "").displayDate.isEmpty
                                            ? "–" : (auth.currentUser?.createdAt ?? "").displayDate)
                                InfoRow(label: "Sprache",
                                        value: auth.currentUser?.language == "de" ? "Deutsch" : "English")
                            }
                        }
                        .padding(.horizontal)

                        // Sign out
                        Button {
                            showSignOutAlert = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Abmelden")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.ttCard)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mein Profil")
                        .font(.system(.headline, design: .serif))
                        .foregroundColor(.ttGold)
                }
            }
            .alert("Abmelden?", isPresented: $showSignOutAlert) {
                Button("Abmelden", role: .destructive) { auth.signOut() }
                Button("Abbrechen", role: .cancel) {}
            }
        }
    }

    private var initials: String {
        let name = auth.currentUser?.displayName ?? "?"
        return name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0).uppercased() } }
            .joined()
    }

    private func saveName() async {
        guard let uid = auth.currentUser?.id else { return }
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? await UserService.shared.updateDisplayName(uid, name: trimmed)
        auth.currentUser?.displayName = trimmed
        editingName = false
    }
}

private struct InfoRow: View {
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
