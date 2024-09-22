//
//  Constants.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import Foundation

struct Constants {
    // DO NOT INCLUDE https
    @UserDefault(key: "baseDomain", defaultValue: "703d-50-247-127-70.ngrok-free.app")
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
                static let humeWebSocket = "/ws/hume" // @deprecated need to add the new route its not a websocket
                static let claudeMessages = "/v3/claude/messages" // TODO: add OpenRouter
                static let embeddingSmall = "/embeddings/small" // can probably cleaner add the small & large embedding endpoints to this constants defintion
                static let embeddingLarge = "/embeddings/large"
            }
        }
        
        struct APIKeys {
            static var openAI: String {
                get { KeychainHelper.read(forKey: "openAIKey") ?? "" }
                set { KeychainHelper.save(newValue, forKey: "openAIKey") }
            }
            
            static var humeAI: String {
                get { KeychainHelper.read(forKey: "humeAIKey") ?? "" }
                set { KeychainHelper.save(newValue, forKey: "humeAIKey") }
            }
            
            static var anthropicAI: String {
                get { KeychainHelper.read(forKey: "anthropicAIKey") ?? "" }
                set { KeychainHelper.save(newValue, forKey: "anthropicAIKey") }
            }
            
            static var gcp: String {
                get { KeychainHelper.read(forKey: "gcpKey") ?? "" }
                set { KeychainHelper.save(newValue, forKey: "gcpKey") }
            }
            
            static var falAPI: String {
                get { KeychainHelper.read(forKey: "falAPIKey") ?? "" }
                set { KeychainHelper.save(newValue, forKey: "falAPIKey") }
            }
            
            static var deepgram: String {
                get { KeychainHelper.read(forKey: "deepgramKey") ?? "" }
                set { KeychainHelper.save(newValue, forKey: "deepgramKey") }
            }
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

    // KeychainHelper as defined earlier
    import Security

    struct KeychainHelper {
        static func save(_ value: String, forKey key: String) {
            let data = Data(value.utf8)
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key,
                kSecValueData: data
            ] as CFDictionary

            SecItemDelete(query) // Delete any existing item
            SecItemAdd(query, nil)
        }

        static func read(forKey key: String) -> String? {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: key,
                kSecReturnData: true,
                kSecMatchLimit: kSecMatchLimitOne
            ] as CFDictionary

            var dataTypeRef: AnyObject?
            let status = SecItemCopyMatching(query, &dataTypeRef)

            if status == errSecSuccess, let data = dataTypeRef as? Data, let string = String(data: data, encoding: .utf8) {
                return string
            }
            return nil
        }
    }
