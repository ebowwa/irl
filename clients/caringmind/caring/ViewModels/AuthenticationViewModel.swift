import Foundation
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    
    private let authService: AuthenticationServiceProtocol
    private let userManager: UserManager
    
    init(authService: AuthenticationServiceProtocol = GoogleAuthService.shared) {
        self.authService = authService
        self.userManager = UserManager.shared
    }
    
    var isAuthenticated: Bool {
        userManager.isAuthenticated
    }
    
    func signInWithGoogle() {
        Task {
            do {
                user = try await authService.signInWithGoogle()
                userManager.signIn()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func signOut() {
        Task {
            do {
                try await authService.signOut()
                user = nil
                userManager.signOut()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
