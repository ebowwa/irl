//
//  Constants.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import Foundation

struct Constants {
    // DO NOT INCLUDE https
    @UserDefault(key: "baseDomain", defaultValue: "33f1-2600-387-f-4812-00-8.ngrok-free.app")
    static var baseDomain: String
    
    @UserDefault(key: "devMode", defaultValue: false)
    static var devMode: Bool
    
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
        // modularize constants into a script just for routes - will require alot of work around the /Services files
        struct Paths {
            static let webSocketPing = "/ws/ping"
            static let testConnection = "/"
            static let upload = "/upload"
            static let whisperTTS = "/ws/WhisperTTS"
            static let humeWebSocket = "/ws/hume" // @deprecated need to add the new route its not a websocket
            static let claudeMessages = "/v3/claude/messages" // TODO: add OpenRouter
            static let embeddingSmall = "/embeddings/small" // can probably cleaner add the small & large embedding endpoints to this constants definition
            static let embeddingLarge = "/embeddings/large"
            
            // SDXL API Path
            static let sdxlGenerate = "/api/sdxl/generate"
            static let sdxlStatus = "api/sdxl/status/"
            static let sdxlResult = "/api/sdxl/result/"
            
            // ** Flux Image Generation API Paths **
            static let imageGenerationSubmit = "/api/FLUXLORAFAL/submit"
            static let imageGenerationStatus = "/api/FLUXLORAFAL/status/"
            static let imageGenerationResult = "/api/FLUXLORAFAL/result/"
        }
    }
    
    struct APIKeys {
        // Store API keys directly in UserDefaults or as constants
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
    
    struct AI_MODELS {
        // Map simplified names to full API names
        static let models: [String: String] = [
            "hauiki-3": "claude-3-haiku-20240307",
            "sonnet-3": "claude-3-sonnet-20240229",
            "opus-3": "claude-3-opus-20240229",
            "sonnet-3.5": "claude-3.5-sonnet-20240320"
        ]
        
        // Simplified names
        static let haiku = "hauiki-3"
        static let sonnet = "sonnet-3"
        static let opus = "opus-3"
        static let sonnet3_5 = "sonnet-3.5"
        
        // Function to retrieve full API name based on simplified name
        static func apiModel(for model: String) -> String? {
            return models[model]
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
