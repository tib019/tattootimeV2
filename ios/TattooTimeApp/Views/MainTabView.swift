import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            BookingView()
                .tabItem {
                    Label("Buchen", systemImage: "calendar.badge.plus")
                }

            MyAppointmentsView()
                .tabItem {
                    Label("Termine", systemImage: "calendar")
                }

            if auth.isAdmin {
                AdminAppointmentsView()
                    .tabItem {
                        Label("Admin", systemImage: "shield.fill")
                    }
            }

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
        }
        .accentColor(.ttGold)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.ttCard)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
