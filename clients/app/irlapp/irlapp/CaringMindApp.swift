// CaringMindApp.swift
// Caringmind

// General App Description: this product is meant to listen 24/7 it uses the openaudio which allows for processing of audio from devices and storing, post requests, websocket, audio playing controls, local audio measurement, etc
// - this app should always be recording, it may be recording for local storage, for batch uploads to server, or for a live-streaming websocket
// - this functionality should not be managed by views, but can be modified, i.e., switch to websocket, send data to server, playbacks, viewing transcriptions, data, etc

// NOTE: this script was updated to include a google sign in which as of now does nothing, it works, the user can sign in with their google account but otherwise this feature has no other extension, moving forward location, usage metrics, drive storage can be applied through this gsignin

//
//  Created by Elijah Arbee on 10/26/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

@main
struct IRLApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var router = AppRouterViewModel()
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(onboardingViewModel)
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let user = user, error == nil {
                            checkAndRegisterUser(user: user)
                        }
                    }
                }
        }
    }

    // New function to check if user is registered and handle registration if necessary
    func checkAndRegisterUser(user: GIDGoogleUser) {
        guard let googleAccountID = user.userID else { return }
        let deviceUUID = DeviceUUID.getUUID()
        
        // Call a function to verify if already registered
        if !isUserRegistered(googleAccountID: googleAccountID, deviceUUID: deviceUUID) {
            // If not registered, register the user
            handleSignIn(user: user)
        }
    }

    // Function to check registration status
    func isUserRegistered(googleAccountID: String, deviceUUID: String) -> Bool {
        // Implement logic to check server or local storage for registration status
        // Return true if user is registered, false otherwise
        // Placeholder return value; replace with actual check
        return false
    }
    
    // Separate function to handle registration after login
    func handleSignIn(user: GIDGoogleUser) {
        guard let idToken = user.idToken?.tokenString else { return }
        let accessToken = user.accessToken.tokenString
        let googleAccountID = user.userID ?? ""
        let deviceUUID = DeviceUUID.getUUID()
        
        registerDeviceWithServer(googleAccountID: googleAccountID, deviceUUID: deviceUUID, idToken: idToken, accessToken: accessToken)
    }
    
    // Function to register the device with the server
    func registerDeviceWithServer(googleAccountID: String, deviceUUID: String, idToken: String, accessToken: String) {
        guard let url = URL(string: "https://2157-2601-646-a201-db60-00-2386.ngrok-free.app/register") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "google_account_id": googleAccountID,
            "device_uuid": deviceUUID,
            "id_token": idToken,
            "access_token": accessToken
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Registration error: \(error.localizedDescription)")
                return
            }
            // Handle server response if needed
        }.resume()
    }
}

// AppDelegate for Google Sign-In URL handling
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// AppRouterViewModel for navigation management
class AppRouterViewModel: ObservableObject {
    @Published var currentDestination: RouterDestination = .splash

    func navigate(to destination: RouterDestination) {
        withAnimation {
            currentDestination = destination
        }
    }

    func navigateToOnboarding() {
        currentDestination = .onboarding
    }

    func navigateToHome() {
        currentDestination = .home
    }
}

enum RouterDestination: Identifiable {
    case splash
    case onboarding
    case home

    var id: UUID {
        UUID()
    }
}


struct ContentView: View {
    @EnvironmentObject var router: AppRouterViewModel
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    var body: some View {
        ZStack {
            switch router.currentDestination {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingIntroView(step: $onboardingViewModel.currentStep,
                                    userName: $onboardingViewModel.userName)
                    .transition(.slide)
            case .home:
                AGIView(serverURL: "ws://2157-2601-646-a201-db60-00-2386.ngrok-free.app/gemini/ws/transcribe")
            }
        }
        .animation(.easeInOut, value: router.currentDestination)
    }
}
