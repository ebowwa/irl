import SwiftUI
import Combine



class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var notificationsEnabled: Bool
    @Published var darkModeEnabled: Bool
    @Published var soundEnabled: Bool
    @Published var devModeEnabled: Bool
    @Published var showTutorial: Bool = false
    @Published var isPresented: Bool = false
    @Published var showingSignOutAlert: Bool = false
    
    // MARK: - Dependencies
    private let authService: GoogleAuthService
    private let settings: AppSettings
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(settings: AppSettings = .shared, authService: GoogleAuthService = .shared) {
        self.settings = settings
        self.authService = authService
        
        // Initialize values from settings
        self.notificationsEnabled = settings.notificationsEnabled
        self.darkModeEnabled = settings.darkModeEnabled
        self.soundEnabled = settings.soundEnabled
        self.devModeEnabled = settings.devModeEnabled
        
        // Setup bindings
        setupBindings()
    }
    
    private func setupBindings() {
        // Bind local changes to settings
        $notificationsEnabled
            .sink { [weak settings] in settings?.notificationsEnabled = $0 }
            .store(in: &cancellables)
        
        $darkModeEnabled
            .sink { [weak settings] in settings?.darkModeEnabled = $0 }
            .store(in: &cancellables)
        
        $soundEnabled
            .sink { [weak settings] in settings?.soundEnabled = $0 }
            .store(in: &cancellables)
        
        $devModeEnabled
            .sink { [weak settings] in settings?.devModeEnabled = $0 }
            .store(in: &cancellables)
            
        $isPresented
            .sink { [weak settings] in settings?.isPresented = $0 }
            .store(in: &cancellables)
            
        $showTutorial
            .sink { [weak settings] in settings?.showTutorial = $0 }
            .store(in: &cancellables)
    }
    
    // MARK: - Settings Management
    func updateSettings() {
        // Synchronize settings with UserDefaults
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - Actions
    func signOut() async throws {
        try await authService.signOut()
        await MainActor.run {
            settings.isAuthenticated = false
            NotificationCenter.default.post(name: .userSignedOut, object: nil)
        }
    }
    
    func postSignOutNotification() {
        NotificationCenter.default.post(name: .userSignedOut, object: nil)
    }
}
