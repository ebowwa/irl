// RUN backend: cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python index.py && ngrok http 8000
//  Constants.swift
//  irlapp
//
//  Created by Elijah Arbee on 10/8/24.
//

import Foundation

struct Constants {
    // Default base domain value for fallback
    private static let defaultBaseDomain = "36e9-2601-646-a201-db60-00-f79e.ngrok-free.app"
    
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
    static let appName = "CaringMind"
    
    // Initialization function for setup (optional)
    static func initializeDefaults() {
        UserDefaults.standard.register(defaults: [
            "baseDomain": defaultBaseDomain,
            "devMode": false,
            "demoMode": false,
            "productionMode": true
        ])
    }
}
