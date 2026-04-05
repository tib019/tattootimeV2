import SwiftUI

@main
struct TattooTimeAppApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
                .task {
                    if auth.isAuthenticated {
                        await auth.loadCurrentUser()
                    }
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        if auth.isAuthenticated && auth.currentUser != nil {
            MainTabView()
        } else if auth.isAuthenticated {
            // Token exists but user profile not loaded yet
            ZStack {
                Color.ttBackground.ignoresSafeArea()
                ProgressView().tint(.ttGold)
            }
            .task { await auth.loadCurrentUser() }
        } else {
            LoginView()
        }
    }
}
