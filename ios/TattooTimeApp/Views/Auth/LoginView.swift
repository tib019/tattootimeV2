import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email    = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        ZStack {
            Color.ttBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                // Logo
                VStack(spacing: 8) {
                    Image(systemName: "pencil.tip.crop.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.ttGold)
                    Text("TattooTime")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                    Text("Dein Tattoo Studio")
                        .font(.subheadline)
                        .foregroundColor(.ttMuted)
                }
                .padding(.top, 60)

                // Form
                VStack(spacing: 16) {
                    TTTextField(placeholder: "E-Mail", text: $email, icon: "envelope")
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    TTTextField(placeholder: "Passwort", text: $password, icon: "lock", isSecure: true)
                }
                .padding(.horizontal)

                // Error
                if let error = auth.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        Task { await auth.signIn(email: email, password: password) }
                    } label: {
                        if auth.isLoading {
                            ProgressView().tint(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("Anmelden")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(Color.ttGold)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(auth.isLoading || email.isEmpty || password.isEmpty)

                    Button {
                        showRegister = true
                    } label: {
                        Text("Noch kein Konto? **Registrieren**")
                            .font(.subheadline)
                            .foregroundColor(.ttMuted)
                    }
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(auth)
        }
    }
}
