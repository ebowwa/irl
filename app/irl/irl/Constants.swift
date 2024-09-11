//
//  Constants.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import Foundation

struct Constants {
    // DO NOT INCLUDE https
    @UserDefault(key: "baseDomain", defaultValue: "bf45-2600-387-f-7718-00-3.ngrok-free.app")
    static var baseDomain: String
    
    // RUN backend: cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python index.py && ngrok http 8000

    struct API {
        static var baseURL: String {
            "https://\(Constants.baseDomain)"
        }
        static var webSocketBaseURL: String {
            "wss://\(Constants.baseDomain)"
        }
        
        struct Paths {
            static let webSocketPing = "/ws/ping"
            static let testConnection = "/"
            static let upload = "/upload"
            static let whisperTTS = "/ws/WhisperTTS"
            static let humeWebSocket = "/ws/hume"
            static let claudeMessages = "/api/v1/messages"  // New path for Claude API
        }
    }
    // -- recent addition; will be adding in the functionality to the app -- not currently used
    struct APIKeys {
        @UserDefault(key: "openAIKey", defaultValue: "")
        static var openAI: String
        
        @UserDefault(key: "humeAIKey", defaultValue: "")
        static var humeAI: String
        
        @UserDefault(key: "anthropicAIKey", defaultValue: "")
        static var anthropicAI: String
        
        @UserDefault(key: "gcpKey", defaultValue: "")
        static var gcp: String
        
        @UserDefault(key: "falAPIKey", defaultValue: "")
        static var falAPI: String
        
        @UserDefault(key: "deepgramKey", defaultValue: "")
        static var deepgram: String
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
