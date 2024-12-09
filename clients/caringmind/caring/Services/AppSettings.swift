//
//  AppSettings.swift
//  caring
//
//  Created by Elijah Arbee on 12/8/24.
//

import SwiftUI
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard
    
    enum Keys {
        static let darkMode = "darkModeEnabled"
        static let notifications = "notificationsEnabled"
        static let sound = "soundEnabled"
        static let devMode = "devModeEnabled"
        static let isAuthenticated = "isAuthenticated"
    }
    
    @Published var isPresented = false
    @Published var darkModeEnabled: Bool {
        didSet {
            defaults.set(darkModeEnabled, forKey: Keys.darkMode)
        }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: Keys.notifications)
        }
    }
    
    @Published var soundEnabled: Bool {
        didSet {
            defaults.set(soundEnabled, forKey: Keys.sound)
        }
    }
    
    @Published var devModeEnabled: Bool {
        didSet {
            defaults.set(devModeEnabled, forKey: Keys.devMode)
        }
    }
    
    @Published var isAuthenticated: Bool {
        didSet {
            defaults.set(isAuthenticated, forKey: Keys.isAuthenticated)
        }
    }
    
    @Published var showTutorial = false
    
    private init() {
        // Load values from UserDefaults with default values as fallback
        self.darkModeEnabled = defaults.object(forKey: Keys.darkMode) as? Bool ?? false
        self.notificationsEnabled = defaults.object(forKey: Keys.notifications) as? Bool ?? true
        self.soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        self.devModeEnabled = defaults.object(forKey: Keys.devMode) as? Bool ?? false
        self.isAuthenticated = defaults.object(forKey: Keys.isAuthenticated) as? Bool ?? false
        
        // Register default values
        let defaultValues: [String: Any] = [
            Keys.darkMode: false,
            Keys.notifications: true,
            Keys.sound: true,
            Keys.devMode: false,
            Keys.isAuthenticated: false
        ]
        defaults.register(defaults: defaultValues)
    }
    
    func updatePresented(_ presented: Bool) {
        DispatchQueue.main.async {
            self.isPresented = presented
        }
    }
    
    func updateShowTutorial(_ show: Bool) {
        DispatchQueue.main.async {
            self.showTutorial = show
        }
    }
    
    func toggleDarkMode() {
        DispatchQueue.main.async {
            self.darkModeEnabled.toggle()
        }
    }
    
    func toggleNotifications() {
        DispatchQueue.main.async {
            self.notificationsEnabled.toggle()
        }
    }
    
    func toggleSound() {
        DispatchQueue.main.async {
            self.soundEnabled.toggle()
        }
    }
}
