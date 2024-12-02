// RUN backend: cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python index.py && ngrok http 8000
//  Constants.swift
//  irlapp
//
//  Created by Elijah Arbee on 10/8/24.
//
import Foundation

struct Constants {
    // Default base domain value for fallback
    private static let defaultBaseDomain = "9419-2a01-4ff-f0-b1f6-00-1.ngrok-free.app"

    // Environment-specific settings
    static let baseDomain: String = {
        // Fetch `baseDomain` from UserDefaults or fall back to default
        UserDefaults.standard.string(forKey: "baseDomain") ?? defaultBaseDomain
    }()

    static let devMode: Bool = {
        UserDefaults.standard.bool(forKey: "devMode")
    }()

    static let demoMode: Bool = {
        UserDefaults.standard.bool(forKey: "demoMode")
    }()

    static let productionMode: Bool = {
        UserDefaults.standard.bool(forKey: "productionMode")
    }()

    // URL configurations
    static var baseURL: String {
        "https://\(baseDomain)"
    }

    static var webSocketBaseURL: String {
        "wss://\(baseDomain)"
    }

    // App-specific constants
    static let appName = "madhi"

    // Initialization function for setup
    static func initializeDefaults() {
        UserDefaults.standard.register(defaults: [
            "baseDomain": defaultBaseDomain,
            "devMode": false,
            "demoMode": false,
            "productionMode": true
        ])
    }
}

// Extension to add more constants
extension Constants {
    static let deviceUUIDService = "MahdiService"
    static let googleAccountIDService = "CaringMindService"
    static let deviceUUIDAccount = "DeviceUUID"
    static let googleAccountIDAccount = "GoogleAccountID"
}
