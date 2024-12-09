import SwiftUI

@MainActor
class UserProfileViewModel: ObservableObject {
    static let shared = UserProfileViewModel()
    
    @Published var username: String = "Your Name"
    private let userManager: UserManager
    
    private init() {
        self.userManager = UserManager.shared
        setupObservers()
        refreshUsername()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileUpdate),
            name: .userProfileUpdated,
            object: nil
        )
    }
    
    @objc private func handleProfileUpdate() {
        refreshUsername()
    }
    
    func refreshUsername() {
        self.username = self.userManager.username
    }
    
    func saveUsername(_ name: String) {
        userManager.saveUsername(name)
        refreshUsername()
    }
    
    func clearUsername() {
        userManager.clearUsername()
        refreshUsername()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
