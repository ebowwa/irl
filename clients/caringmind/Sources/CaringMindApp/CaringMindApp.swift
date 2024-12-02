import caringmind
import GoogleSignIn
import SwiftUI

@main
struct CaringMindAppMain: App {
    @StateObject private var appState = AppState()
    @StateObject private var router = AppRouterViewModel()
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @StateObject private var authManager = AuthenticationManager.shared

    init() {
        GoogleSignInConfig.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(router)
                .environmentObject(onboardingViewModel)
                .environmentObject(authManager)
        }
    }
}
