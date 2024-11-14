// CaringMindApp.swift
// Caringmind

// General App Description: this product is meant to listen 24/7 it uses the openaudio which allows for processing of audio from devices and storing, post requests, websocket, audio playing controls, local audio measurement, etc
// - this app should always be recording, it may be recording for local storage, for batch uploads to server, or for a live-streaming websocket
// - this functionality should not be managed by views, but can be modified, i.e., switch to websocket, send data to server, playbacks, viewing transcriptions, data, etc

// NOTE: this script was updated to include a google sign in which as of now does nothing, it works, the user can sign in with their google account but otherwise this feature has no other extension, moving forward location, usage metrics, drive storage can be applied through this gsignin

//
//  Created by Elijah Arbee on 10/26/24.
//
//
//  Created by Elijah Arbee on 10/26/24.
//

//
//  Created by Elijah Arbee on 10/26/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift

@main
struct irlApp: App {
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
                        if let error = error {
                            print("Restore sign-in failed with error: \(error.localizedDescription)")
                            // Optionally, navigate to sign-in screen
                            return
                        }
                        if let user = user {
                            print("Successfully restored previous sign-in for user ID: \(user.userID ?? "nil")")
                            checkAndRegisterUser(user: user)
                        } else {
                            print("No previous sign-in found.")
                            // Optionally, prompt user to sign in
                        }
                    }
                }
        }
    }

    /// Checks if the user is registered and registers them if not.
    func checkAndRegisterUser(user: GIDGoogleUser) {
        guard let googleAccountID = user.userID else {
            print("checkAndRegisterUser: user.userID is nil.")
            return
        }

        print("checkAndRegisterUser: googleAccountID = \(googleAccountID)")

        let deviceUUID = DeviceUUID.getUUID()

        // Perform an asynchronous check
        Task {
            do {
                let checkResponse = try await isUserRegistered(googleAccountID: googleAccountID, deviceUUID: deviceUUID)
                if checkResponse.is_registered {
                    print("User is already registered.")
                    // Optionally, navigate to the home screen or perform other actions
                } else {
                    print("User not registered. Proceeding to handle sign-in.")
                    handleSignIn(user: user)
                }
            } catch {
                print("Error checking registration status: \(error.localizedDescription)")
                // Handle the error appropriately, possibly by notifying the user
            }
        }
    }

    /// Asynchronously checks if the user is registered by communicating with the backend.
    /// - Parameters:
    ///   - googleAccountID: The Google Account ID of the user.
    ///   - deviceUUID: The UUID of the device.
    /// - Returns: A `DeviceRegistrationCheckResponse` indicating registration status.
    func isUserRegistered(googleAccountID: String, deviceUUID: String) async throws -> DeviceRegistrationCheckResponse {
        // Construct the URL for the check endpoint
        guard let url = URL(string: "https://2157-2601-646-a201-db60-00-2386.ngrok-free.app/device/register/check") else {
            throw URLError(.badURL)
        }

        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "google_account_id": googleAccountID,
            "device_uuid": deviceUUID
        ]
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Serialize the request body
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        // Perform the network request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check the response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 200:
            // Parse the JSON response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let checkResponse = try decoder.decode(DeviceRegistrationCheckResponse.self, from: data)
            return checkResponse
        case 400:
            // Handle bad request
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.badRequest(errorResponse.detail)
        case 404:
            // Not found, treat as not registered
            return DeviceRegistrationCheckResponse(is_registered: false, device: nil)
        default:
            // Handle other status codes
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.serverError(httpResponse.statusCode, errorResponse.detail)
        }
    }

    /// Handles the sign-in process by registering the device with the server.
    /// - Parameter user: The authenticated Google user.
    func handleSignIn(user: GIDGoogleUser) {
        guard let idToken = user.idToken?.tokenString else {
            print("handleSignIn: idToken is nil.")
            return
        }
        let accessToken = user.accessToken.tokenString
        let googleAccountID = user.userID ?? ""
        let deviceUUID = DeviceUUID.getUUID()

        print("handleSignIn: Registering device with server.")
        Task {
            do {
                try await registerDeviceWithServer(googleAccountID: googleAccountID, deviceUUID: deviceUUID, idToken: idToken, accessToken: accessToken)
                print("Device registered successfully.")
                // Optionally, navigate to the home screen or perform other actions
            } catch {
                print("registerDeviceWithServer: Registration error - \(error.localizedDescription)")
                // Handle the error appropriately, possibly by notifying the user
            }
        }
    }

    /// Asynchronously registers the device with the backend server.
    /// - Parameters:
    ///   - googleAccountID: The Google Account ID of the user.
    ///   - deviceUUID: The UUID of the device.
    ///   - idToken: The ID token for authentication.
    ///   - accessToken: The access token for authentication.
    func registerDeviceWithServer(googleAccountID: String, deviceUUID: String, idToken: String, accessToken: String) async throws {
        // Construct the URL for the registration endpoint
        guard let url = URL(string: "https://2157-2601-646-a201-db60-00-2386.ngrok-free.app/device/register") else {
            throw URLError(.badURL)
        }

        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body: [String: Any] = [
            "google_account_id": googleAccountID,
            "device_uuid": deviceUUID,
            "id_token": idToken,
            "access_token": accessToken
        ]
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Serialize the request body
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        // Perform the network request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check the response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 201:
            // Successfully registered
            print("Device registered successfully.")
            // Optionally, parse the response data if needed
        case 400:
            // Handle bad request
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.badRequest(errorResponse.detail)
        case 500:
            // Handle server error
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.serverError(httpResponse.statusCode, errorResponse.detail)
        default:
            // Handle other status codes
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
            throw RegistrationError.serverError(httpResponse.statusCode, errorResponse.detail)
        }
    }
}

// MARK: - Supporting Models and Enums

/// Represents the response from the device registration check endpoint.
struct DeviceRegistrationCheckResponse: Codable {
    let is_registered: Bool
    let device: DeviceRegistrationEntry?
}

/// Represents an error response from the backend.
struct ErrorResponse: Codable {
    let detail: String
}

/// Represents the device registration entry as returned by the backend.
struct DeviceRegistrationEntry: Codable {
    let id: Int
    let google_account_id: String
    let device_uuid: String
    let id_token: String
    let access_token: String
    let created_at: String // Consider using Date with appropriate decoding
}

/// Defines possible registration errors.
enum RegistrationError: Error, LocalizedError {
    case badRequest(String)
    case serverError(Int, String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .badRequest(let message):
            return "Bad Request: \(message)"
        case .serverError(let code, let message):
            return "Server Error (\(code)): \(message)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

// MARK: - AppDelegate for Google Sign-In URL handling

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
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
