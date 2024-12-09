import SwiftUI
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    // MARK: - Published Properties
    @Published var username: String = "Your Name"
    @Published var joinDate: Date = Date()
    @Published var moments: Int = 0
    @Published var hoursListened: Double = 0
    @Published var growthPercentage: Int = 0
    @Published var timelineMoments: [Moment] = []
    @Published var isAuthenticated: Bool = false
    
    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys: String {
        case username = "user_name"
        case joinDate = "join_date"
        case moments = "moments_count"
        case hoursListened = "hours_listened"
        case growthPercentage = "growth_percentage"
        case timelineMoments = "timeline_moments"
        case isAuthenticated = "is_authenticated"
        
        static var allKeys: [String] {
            return [
                username.rawValue,
                joinDate.rawValue,
                moments.rawValue,
                hoursListened.rawValue,
                growthPercentage.rawValue,
                timelineMoments.rawValue,
                isAuthenticated.rawValue
            ]
        }
    }
    
    private let defaults = UserDefaults.standard
    
    private init() {
        loadUserData()
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSignOut),
            name: .userSignedOut,
            object: nil
        )
    }
    
    @objc private func handleSignOut() {
        isAuthenticated = false
        clearUserData()
    }
    
    // MARK: - Authentication Management
    func signIn() {
        isAuthenticated = true
        defaults.set(true, forKey: UserDefaultsKeys.isAuthenticated.rawValue)
        defaults.synchronize()
        NotificationCenter.default.post(name: .userAuthenticationChanged, object: nil)
    }
    
    func signOut() {
        isAuthenticated = false
        defaults.set(false, forKey: UserDefaultsKeys.isAuthenticated.rawValue)
        defaults.synchronize()
        clearUserData()
        NotificationCenter.default.post(name: .userAuthenticationChanged, object: nil)
    }
    
    // MARK: - User Data Management
    func loadUserData() {
        username = defaults.string(forKey: UserDefaultsKeys.username.rawValue) ?? "Your Name"
        joinDate = defaults.object(forKey: UserDefaultsKeys.joinDate.rawValue) as? Date ?? Date()
        moments = defaults.integer(forKey: UserDefaultsKeys.moments.rawValue)
        hoursListened = defaults.double(forKey: UserDefaultsKeys.hoursListened.rawValue)
        growthPercentage = defaults.integer(forKey: UserDefaultsKeys.growthPercentage.rawValue)
        isAuthenticated = defaults.bool(forKey: UserDefaultsKeys.isAuthenticated.rawValue)
        loadMoments()
    }
    
    private func loadMoments() {
        if let data = defaults.data(forKey: UserDefaultsKeys.timelineMoments.rawValue),
           let decodedMoments = try? JSONDecoder().decode([Moment].self, from: data) {
            timelineMoments = decodedMoments
        }
    }
    
    private func saveMoments() {
        if let encoded = try? JSONEncoder().encode(timelineMoments) {
            defaults.set(encoded, forKey: UserDefaultsKeys.timelineMoments.rawValue)
        }
    }
    
    func addMoment(_ moment: Moment) {
        timelineMoments.insert(moment, at: 0)
        saveMoments()
        incrementMoments()
        NotificationCenter.default.post(name: .timelineUpdated, object: nil)
    }
    
    func saveUsername(_ name: String) {
        username = name
        defaults.set(name, forKey: UserDefaultsKeys.username.rawValue)
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
    }
    
    func updateJoinDate(_ date: Date) {
        joinDate = date
        defaults.set(date, forKey: UserDefaultsKeys.joinDate.rawValue)
    }
    
    func incrementMoments() {
        moments += 1
        defaults.set(moments, forKey: UserDefaultsKeys.moments.rawValue)
    }
    
    func updateHoursListened(_ hours: Double) {
        hoursListened = hours
        defaults.set(hours, forKey: UserDefaultsKeys.hoursListened.rawValue)
    }
    
    func updateGrowthPercentage(_ percentage: Int) {
        growthPercentage = percentage
        defaults.set(percentage, forKey: UserDefaultsKeys.growthPercentage.rawValue)
    }
    
    func clearUsername() {
        username = "Your Name"
        defaults.removeObject(forKey: UserDefaultsKeys.username.rawValue)
        defaults.synchronize()
        NotificationCenter.default.post(name: .userProfileUpdated, object: nil)
    }
    
    private func clearUserData() {
        username = "Your Name"
        joinDate = Date()
        moments = 0
        hoursListened = 0
        growthPercentage = 0
        timelineMoments = []
        
        // Clear UserDefaults
        UserDefaultsKeys.allKeys.forEach { key in
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
    static let timelineUpdated = Notification.Name("timelineUpdated")
    static let userAuthenticationChanged = Notification.Name("userAuthenticationChanged")
    static let userSignedOut = Notification.Name("userSignedOut")
}
