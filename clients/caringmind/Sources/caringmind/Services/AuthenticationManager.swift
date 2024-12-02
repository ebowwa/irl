import Foundation
import GoogleSignIn
import SwiftUI

public enum AuthError: Error {
    case signInFailed(Error)
    case noUserID
    case invalidToken
    case unknown
}

@MainActor
public final class AuthenticationManager: ObservableObject {
    @Published public var isAuthenticated = false
    @Published public var userProfile: GIDProfileData?
    @Published public var userID: String?
    @Published public var userName: String?
    @Published public var userEmail: String?
    @Published public var authError: AuthError?

    public static let shared = AuthenticationManager()

    private init() {
        checkExistingSignIn()
    }

    public func signInWithGoogle(user: GIDGoogleUser) {
        do {
            userProfile = user.profile
            userID = user.userID
            userName = user.profile?.name
            userEmail = user.profile?.email

            if let userId = user.userID {
                KeychainHelper.standard.saveGoogleAccountID(userId)
                if let accessToken = user.accessToken.tokenString {
                    KeychainHelper.standard.saveAuthToken(accessToken)
                }
                isAuthenticated = true
                authError = nil
            } else {
                throw AuthError.noUserID
            }
        } catch {
            authError = error as? AuthError ?? .unknown
            isAuthenticated = false
        }
    }

    public func signOut() {
        GIDSignIn.sharedInstance.signOut()
        KeychainHelper.standard.deleteGoogleAccountID()
        KeychainHelper.standard.deleteAuthToken()
        isAuthenticated = false
        userProfile = nil
        userID = nil
        userName = nil
        userEmail = nil
        authError = nil
    }

    public func checkExistingSignIn() {
        if let googleID = KeychainHelper.standard.getGoogleAccountID(),
           let _ = KeychainHelper.standard.getAuthToken() {
            userID = googleID
            isAuthenticated = true

            // Restore Google Sign-In state if possible
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard let self = self else { return }

                if let error = error {
                    self.authError = .signInFailed(error)
                    self.signOut() // Clear invalid state
                    return
                }

                if let user = user {
                    self.userProfile = user.profile
                    self.userName = user.profile?.name
                    self.userEmail = user.profile?.email
                }
            }
        }
    }
}
