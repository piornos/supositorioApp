import SwiftUI

@main
struct SupositorioApp: App {
    @StateObject private var session = UserSession()
    @AppStorage("appTheme") private var appTheme: Int = 0
    
    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    DashboardView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(session)
            .tint(.indigo)
            .preferredColorScheme(appTheme == 0 ? nil : (appTheme == 1 ? .light : .dark))
        }
    }
}
