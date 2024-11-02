// RUN backend: cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python index.py && ngrok http 8000
//
//  Constants.swift
//  irlapp
//
//  Created by Elijah Arbee on 10/8/24.
//

import Foundation

struct Constants {
    // Environment-specific settings
    static let baseDomain = UserDefaults.standard.string(forKey: "baseDomain") ?? "36e9-2601-646-a201-db60-00-f79e.ngrok-free.app"
    static let devMode = UserDefaults.standard.bool(forKey: "devMode") // Default is `false` if not set
    static let demoMode = UserDefaults.standard.bool(forKey: "demoMode") // Default is `false` if not set
    static let productionMode = UserDefaults.standard.bool(forKey: "productionMode") // Default is `true` if not set

    // URL configurations
    static var baseURL: String {
        "https://\(baseDomain)"
    }
    static var webSocketBaseURL: String {
        "wss://\(baseDomain)"
    }
    
    // App-specific constants
    static let appName = "CaringMind"
    
    // Initialization function for setup (optional)
    static func initializeDefaults() {
        UserDefaults.standard.register(defaults: [
            "baseDomain": "36e9-2601-646-a201-db60-00-f79e.ngrok-free.app",
            "devMode": false,
            "demoMode": false,
            "productionMode": true
        ])
    }
}
