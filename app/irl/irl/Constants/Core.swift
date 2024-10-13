//  RL/Constants/Core
//  Core.swift
//  ProjectIRL
//
//  Created by Elijah Arbee on 10/8/24.
//

import Foundation

struct Constants {
    // DO NOT INCLUDE https
    @UserDefault(key: "baseDomain", defaultValue: "26c8-2a01-4ff-f0-42e0-00-1.ngrok-free.app")
    static var baseDomain: String
    
    // Refracted but need to return to run tests not on production
    @UserDefault(key: "devMode", defaultValue: false)
    static var devMode: Bool
    
    @UserDefault(key: "demoMode", defaultValue: false)
    static var demoMode: Bool
    
    @UserDefault(key: "productionMode", defaultValue: true)
    static var productionMode: Bool
    
    // RUN backend: cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python index.py && ngrok http 8000
    static let appName = "irl"

    struct API {
        static var baseURL: String {
            "https://\(Constants.baseDomain)"
        }
        static var webSocketBaseURL: String {
            "wss://\(Constants.baseDomain)"
        }
    }
}

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}
