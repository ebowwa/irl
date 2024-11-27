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

@main
struct mahdiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var router = AppRouterViewModel()
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    // Instances of registration handlers
    private let checkRegistrationHandler = CheckDeviceServerRegistration()
    private let registerDeviceHandler = RegisterDeviceToServer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(onboardingViewModel)
                .onAppear {
                    Constants.initializeDefaults()
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let error = error {
                            print("Restore sign-in failed with error: \(error.localizedDescription)")
                            return
                        }
                        if let user = user {
                            print("Successfully restored previous sign-in for user ID: \(user.userID ?? "nil")")
                            checkAndRegisterUser(user: user)
                        } else {
                            print("No previous sign-in found.")
                        }
                    }
                }
        }
    }

    /// Checks if the user is registered and registers them if not.
    /// - Parameter user: The authenticated Google user.
    func checkAndRegisterUser(user: GIDGoogleUser) {
        // Proceed to check with the server regardless of local status
        guard let googleAccountID = user.userID else {
            print("checkAndRegisterUser: user.userID is nil.")
            return
        }

        print("checkAndRegisterUser: googleAccountID = \(googleAccountID)")

        let deviceUUID = DeviceUUID.getUUID()

        // Perform an asynchronous check with the backend server
        Task {
            do {
                let checkResponse = try await checkRegistrationHandler.isUserRegistered(
                    googleAccountID: googleAccountID, deviceUUID: deviceUUID ?? "")
                if checkResponse.is_registered, checkResponse.device != nil {
                    print("User is already registered on server.")
                    // Update local registration status based on server response
                    RegistrationStatus.setDeviceRegistered(true)
                    // Optionally, navigate to the home screen or perform other actions
                } else {
                    print("User not registered on server. Proceeding to register.")
                    handleSignIn(user: user)
                }
            } catch {
                print("Error checking registration status: \(error.localizedDescription)")
                // Handle the error appropriately, possibly by notifying the user
                // Optionally, set local registration status to false
                RegistrationStatus.setDeviceRegistered(false)
            }
        }
    }

    /// Handles the sign-in process by registering the device with the server.
    /// Integrates updating the local registration status upon successful registration.
    /// - Parameter user: The authenticated Google user.
    func handleSignIn(user: GIDGoogleUser) {
        guard let idToken = user.idToken?.tokenString else {
            print("handleSignIn: idToken is nil.")
            return
        }
        let accessToken = user.accessToken.tokenString
        let googleAccountID = user.userID ?? ""
        let deviceUUID = DeviceUUID.getUUID()

        // Save googleAccountID to Keychain
        KeychainHelper.standard.saveGoogleAccountID(googleAccountID)

        print("handleSignIn: Registering device with server.")
        Task {
            do {
                try await registerDeviceHandler.registerDeviceWithServer(
                    googleAccountID: googleAccountID,
                    deviceUUID: deviceUUID ?? "",
                    idToken: idToken,
                    accessToken: accessToken
                )
                print("Device registered successfully.")
                // RegistrationStatus is updated within RegisterDeviceToServer upon success
            } catch {
                print("registerDeviceWithServer: Registration error - \(error.localizedDescription)")
                // Handle the error appropriately
                RegistrationStatus.setDeviceRegistered(false)
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

// MARK: - ContentView

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
                OnboardingIntroView(
                    step: $onboardingViewModel.currentStep,
                    userName: $onboardingViewModel.userName
                )
                // can we hold the results in state of the audio upload genai uri's and audio and responses so that we can save to account when they create the account
                .transition(.slide)
                // transitions on google signed in right now
                
            case .home:
                MainContentView()
            }
        }
        .animation(.easeInOut, value: router.currentDestination)
    }
}
