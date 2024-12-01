//
//  UserRegistrationManager.swift
//  CaringMind
//
//  Updated to remove ReSwift and use SwiftUI's ObservableObject for state management.
//

import Foundation
import GoogleSignIn

// MARK: - UserRegistrationManager
class UserRegistrationManager {
    private let checkRegistrationHandler: CheckDeviceServerRegistration
    private let registerDeviceHandler: RegisterDeviceToServer
    private let appState: AppState
    
    init(
        checkRegistrationHandler: CheckDeviceServerRegistration = CheckDeviceServerRegistration(),
        registerDeviceHandler: RegisterDeviceToServer = RegisterDeviceToServer(),
        appState: AppState
    ) {
        self.checkRegistrationHandler = checkRegistrationHandler
        self.registerDeviceHandler = registerDeviceHandler
        self.appState = appState
    }
    
    func initiateRegistration(for user: GIDGoogleUser) {
        guard let googleAccountID = user.userID else {
            print("UserRegistrationManager: user.userID is nil.")
            appState.handleRegistrationFailure(error: "Invalid Google Account ID.")
            return
        }
        
        let deviceUUID = DeviceUUID.getUUID()
        
        // Save Google Account ID to Keychain
        KeychainHelper.standard.saveGoogleAccountID(googleAccountID)
        
        Task {
            do {
                let checkResponse = try await checkRegistrationHandler.isUserRegistered(
                    googleAccountID: googleAccountID,
                    deviceUUID: deviceUUID
                )
                
                if checkResponse.is_registered, checkResponse.device != nil {
                    print("UserRegistrationManager: User is already registered on server.")
                    await MainActor.run {
                        appState.handleRegistrationSuccess(deviceUUID: deviceUUID)
                    }
                } else {
                    print("UserRegistrationManager: User not registered on server. Proceeding to register.")
                    try await registerDevice(user: user, googleAccountID: googleAccountID, deviceUUID: deviceUUID)
                }
            } catch {
                print("UserRegistrationManager: Error checking registration status - \(error.localizedDescription)")
                await MainActor.run {
                    appState.handleRegistrationFailure(error: error.localizedDescription)
                }
            }
        }
    }
    
    private func registerDevice(user: GIDGoogleUser, googleAccountID: String, deviceUUID: String) async throws {
        guard let idToken = user.idToken?.tokenString else {
            print("UserRegistrationManager: idToken is nil.")
            await MainActor.run {
                appState.handleRegistrationFailure(error: "ID Token is missing.")
            }
            throw RegistrationError.badRequest("ID Token is missing.")
        }
        
        let accessToken = user.accessToken.tokenString
        
        do {
            try await registerDeviceHandler.registerDeviceWithServer(
                googleAccountID: googleAccountID,
                deviceUUID: deviceUUID,
                idToken: idToken,
                accessToken: accessToken
            )
            print("UserRegistrationManager: Device registered successfully.")
            await MainActor.run {
                appState.handleRegistrationSuccess(deviceUUID: deviceUUID)
            }
        } catch {
            print("UserRegistrationManager: Registration error - \(error.localizedDescription)")
            await MainActor.run {
                appState.handleRegistrationFailure(error: error.localizedDescription)
            }
            throw error
        }
    }
}
