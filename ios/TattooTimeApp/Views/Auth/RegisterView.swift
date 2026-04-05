import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email       = ""
    @State private var password    = ""
    @State private var passwordConfirm = ""

    private var passwordMismatch: Bool { !password.isEmpty && password != passwordConfirm }
    private var canSubmit: Bool {
        !displayName.isEmpty && email.contains("@") &&
        password.count >= 6 && password == passwordConfirm
    }

    var body: some View {
        ZStack {
            Color.ttBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.ttMuted)
                                .padding(8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    Text("Konto erstellen")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.white)

                    VStack(spacing: 16) {
                        TTTextField(placeholder: "Name", text: $displayName, icon: "person")
                        TTTextField(placeholder: "E-Mail", text: $email, icon: "envelope")
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        TTTextField(placeholder: "Passwort (min. 6 Zeichen)", text: $password, icon: "lock", isSecure: true)
                        TTTextField(placeholder: "Passwort bestätigen", text: $passwordConfirm, icon: "lock.fill", isSecure: true)
                    }
                    .padding(.horizontal)

                    if passwordMismatch {
                        Text("Passwörter stimmen nicht überein.")
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    if let error = auth.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button {
                        Task {
                            await auth.register(email: email, password: password, displayName: displayName)
                            if auth.isAuthenticated { dismiss() }
                        }
                    } label: {
                        if auth.isLoading {
                            ProgressView().tint(.black)
                                .frame(maxWidth: .infinity).frame(height: 50)
                        } else {
                            Text("Registrieren")
                                .font(.headline).foregroundColor(.black)
                                .frame(maxWidth: .infinity).frame(height: 50)
                        }
                    }
                    .background(canSubmit ? Color.ttGold : Color.ttCard)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(!canSubmit || auth.isLoading)

                    Spacer()
                }
                .padding(.top, 16)
            }
        }
    }
}
