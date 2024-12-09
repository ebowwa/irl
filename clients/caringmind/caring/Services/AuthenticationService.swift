import Foundation
import GoogleSignIn
import GoogleSignInSwift

// Protocol for authentication service
protocol AuthenticationServiceProtocol {
    func signInWithGoogle() async throws -> User
    func signOut() async throws
    var currentUser: User? { get }
}

// User model that's independent of the authentication provider
struct User: Codable {
    let id: String
    let email: String?
    let name: String?
    let photoURL: URL?
}

// Google Authentication Implementation
class GoogleAuthService: AuthenticationServiceProtocol {
    static let shared = GoogleAuthService()
    private var currentGoogleUser: GIDGoogleUser?
    
    var currentUser: User? {
        guard let googleUser = currentGoogleUser else { return nil }
        return User(
            id: googleUser.userID ?? "",
            email: googleUser.profile?.email,
            name: googleUser.profile?.name,
            photoURL: googleUser.profile?.imageURL(withDimension: 100)
        )
    }
    
    func signInWithGoogle() async throws -> User {
        guard let topVC = await UIApplication.shared.topViewController() else {
            throw AuthError.presentationError
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        self.currentGoogleUser = gidSignInResult.user
        
        guard let user = self.currentUser else {
            throw AuthError.invalidUser
        }
        
        return user
    }
    
    func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
        self.currentGoogleUser = nil
    }
}

// Custom errors
enum AuthError: Error {
    case invalidUser
    case presentationError
    case unknown
}

// Helper extension to get top view controller
extension UIApplication {
    func topViewController() async -> UIViewController? {
        let scenes = await self.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window?.rootViewController?.topViewController()
    }
}

extension UIViewController {
    func topViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topViewController()
        }
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topViewController() ?? navigation
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topViewController() ?? tab
        }
        return self
    }
}
