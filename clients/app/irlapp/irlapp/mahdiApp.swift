//
//  CaringMindApp.swift
//  CaringMind
//
//  General App Description: this product is meant to listen 24/7 it uses the openaudio which allows for processing of audio from devices and storing, post requests, websocket, audio playing controls, local audio measurement, etc
// - this app should always be recording, it may be recording for local storage, for batch uploads to server, or for a live-streaming websocket
// - this functionality should not be managed by views, but can be modified, i.e., switch to websocket, send data to server, playbacks, viewing transcriptions, data, etc
//
// NOTE: this script was updated to include a google sign in which as of now does nothing, it works, the user can sign in with their google account but otherwise this feature has no other extension, moving forward location, usage metrics, drive storage can be applied through this gsignin

import GoogleSignIn
import GoogleSignInSwift
import SwiftUI

// MARK: - App State Management

// Define the AppState which holds the entire state of the application
class AppState: ObservableObject {
    // User State
    @Published var isSignedIn: Bool = false
    @Published var userID: String? = nil
    @Published var userError: String? = nil
    
    // Registration State
    @Published var isRegistered: Bool = false
    @Published var deviceUUID: String? = nil
    @Published var registrationError: String? = nil
    
    // Onboarding State
    @Published var onboardingStep: OnboardingStep = .intro
    @Published var userName: String = ""
    
    // Router State
    @Published var currentDestination: RouterDestination = .splash
    
    // Audio State
    @Published var isRecording: Bool = false
    @Published var audioData: [AudioData] = []
    
    // Instance of UserRegistrationManager
    // Use lazy to ensure 'self' is available when initializing
    lazy private var userRegistrationManager = UserRegistrationManager(appState: self)
    
    // Handle Sign-In
    func handleSignIn(user: GIDGoogleUser) {
        self.isSignedIn = true
        self.userID = user.userID
        self.userError = nil
        // Initiate registration
        userRegistrationManager.initiateRegistration(for: user)
    }
    
    // Handle Sign-In Failure
    func handleSignInFailure(error: String) {
        self.userError = error
        self.isSignedIn = false
    }
    
    // Registration Success
    func handleRegistrationSuccess(deviceUUID: String) {
        self.isRegistered = true
        self.deviceUUID = deviceUUID
        self.registrationError = nil
        // Navigate to home upon successful registration
        navigate(to: .home)
    }
    
    // Registration Failure
    func handleRegistrationFailure(error: String) {
        self.isRegistered = false
        self.registrationError = error
    }
    
    // Navigation
    func navigate(to destination: RouterDestination) {
        withAnimation {
            self.currentDestination = destination
        }
    }
    
    // Audio Controls
    func startRecording() {
        self.isRecording = true
        // Add additional logic to start recording
    }
    
    func stopRecording() {
        self.isRecording = false
        // Add additional logic to stop recording
    }
    
    func addAudioData(_ data: AudioData) {
        self.audioData.append(data)
    }
}

// Define Onboarding Steps
enum OnboardingStep {
    case intro
    case permissions
    case completion
}

// MARK: - AudioData Structure

struct AudioData: Identifiable {
    var id: UUID
    var data: Data
    var timestamp: Date
}

// MARK: - Main App Structure

@main
struct mahdiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @StateObject private var router = AppRouterViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(router)
                .environmentObject(onboardingViewModel)
                .onAppear {
                    Constants.initializeDefaults()
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let error = error {
                            print("Restore sign-in failed with error: \(error.localizedDescription)")
                            // Handle sign-in failure
                            appState.handleSignInFailure(error: error.localizedDescription)
                            return
                        }
                        if let user = user {
                            print("Successfully restored previous sign-in for user ID: \(user.userID ?? "nil")")
                            // Handle successful sign-in
                            appState.handleSignIn(user: user)
                        } else {
                            print("No previous sign-in found.")
                        }
                    }
                }
        }
    }
}

// MARK: - AppDelegate for Google Sign-In URL handling

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication, open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - AppRouterViewModel for navigation management

class AppRouterViewModel: ObservableObject {
    @Published var currentDestination: RouterDestination = .splash
    
    func navigate(to destination: RouterDestination) {
        withAnimation {
            self.currentDestination = destination
        }
    }
    
    func navigateToOnboarding() {
        self.navigate(to: .onboarding)
    }
    
    func navigateToHome() {
        self.navigate(to: .home)
    }
}

// MARK: - RouterDestination Enum

enum RouterDestination: Identifiable {
    case splash
    case onboarding
    case home

    var id: UUID {
        UUID()
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var router: AppRouterViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            switch router.currentDestination {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingIntroView(
                    step: $onboardingViewModel.currentStep,
                    userName: $onboardingViewModel.userName
                )
                .transition(.slide)
            case .home:
                MainContentView()
            }
        }
        .animation(.easeInOut, value: router.currentDestination)
        .onAppear {
            // Example: You can perform additional setup here if needed
        }
    }
}

/** currently :
        - Splash page (two options) : login -> MainContentView
        - Onboarding Tutorial: Name Input, TruthLieGame -> SignIn/Up -> MainContentView
*/
