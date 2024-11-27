//
//  UserRegistrationManager.swift
//  CaringMind
//
//

import Foundation
import GoogleSignIn
import ReSwift

// MARK: - UserRegistrationManager

class UserRegistrationManager {
    // Dependencies
    private let checkRegistrationHandler: CheckDeviceServerRegistration
    private let registerDeviceHandler: RegisterDeviceToServer
    private let store: Store<AppState>
    
    // Initializer with dependency injection
    init(
        checkRegistrationHandler: CheckDeviceServerRegistration = CheckDeviceServerRegistration(),
        registerDeviceHandler: RegisterDeviceToServer = RegisterDeviceToServer(),
        store: Store<AppState> = mainStore
    ) {
        self.checkRegistrationHandler = checkRegistrationHandler
        self.registerDeviceHandler = registerDeviceHandler
        self.store = store
    }
    
    /// Initiates the user registration process.
    /// - Parameter user: The authenticated Google user.
    func initiateRegistration(for user: GIDGoogleUser) {
        guard let googleAccountID = user.userID else {
            print("UserRegistrationManager: user.userID is nil.")
            store.dispatch(RegistrationFailureAction(error: "Invalid Google Account ID."))
            return
        }
        
        let deviceUUID = DeviceUUID.getUUID()
        
        // Save Google Account ID to Keychain
        KeychainHelper.standard.saveGoogleAccountID(googleAccountID)
        
        // Perform an asynchronous check with the backend server
        Task {
            do {
                let checkResponse = try await checkRegistrationHandler.isUserRegistered(
                    googleAccountID: googleAccountID,
                    deviceUUID: deviceUUID
                )
                
                if checkResponse.is_registered, checkResponse.device != nil {
                    print("UserRegistrationManager: User is already registered on server.")
                    store.dispatch(RegistrationSuccessAction(deviceUUID: deviceUUID))
                    store.dispatch(NavigateAction(destination: .home))
                } else {
                    print("UserRegistrationManager: User not registered on server. Proceeding to register.")
                    try await registerDevice(user: user, googleAccountID: googleAccountID, deviceUUID: deviceUUID)
                }
            } catch {
                print("UserRegistrationManager: Error checking registration status - \(error.localizedDescription)")
                store.dispatch(RegistrationFailureAction(error: error.localizedDescription))
                RegistrationStatus.setDeviceRegistered(false)
            }
        }
    }
    
    /// Registers the device with the server.
    /// - Parameters:
    ///   - user: The authenticated Google user.
    ///   - googleAccountID: The Google account ID.
    ///   - deviceUUID: The device UUID.
    private func registerDevice(user: GIDGoogleUser, googleAccountID: String, deviceUUID: String) async throws {
        guard let idToken = user.idToken?.tokenString else {
            print("UserRegistrationManager: idToken is nil.")
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
            store.dispatch(RegistrationSuccessAction(deviceUUID: deviceUUID))
            store.dispatch(NavigateAction(destination: .home))
        } catch {
            print("UserRegistrationManager: Registration error - \(error.localizedDescription)")
            store.dispatch(RegistrationFailureAction(error: error.localizedDescription))
            RegistrationStatus.setDeviceRegistered(false)
            throw error
        }
    }
}
