import SwiftUI
import SwiftData

// MARK: - Root View
struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding {
            ContentView()
        } else {
            WelcomeView()
        }
    }
}

// MARK: - Content View
struct ContentView: View {
    var body: some View {
        DashboardComponentsView()
            .ignoresSafeArea(.container, edges: .bottom)
    }
}