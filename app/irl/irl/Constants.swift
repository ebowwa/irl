//  Constants.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
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
            static let embeddingSmall = "/embeddings/small" // can probably cleaner add the small & large embedding endpoints to this constants definition
            static let embeddingLarge = "/embeddings/large"
            
            // SDXL API Path
            static let sdxlGenerate = "/api/sdxl/generate"
            
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





/**
 The **Keychain** was included in your original code to securely store sensitive data such as API keys. It provides a safe way to manage confidential information, particularly because **storing sensitive data like API keys or passwords directly in your code or using less secure storage methods (like `UserDefaults`)** can expose your app to security risks.

 ### **Why the Keychain Was Used:**

 1. **Security**:
    - The Keychain is a secure storage mechanism provided by Apple. It encrypts sensitive data, ensuring that it’s stored safely and can only be accessed by the app or service that stored it. This makes it a more secure choice than storing sensitive data directly in the app’s code or `UserDefaults`, which is unencrypted.
    
 2. **Confidentiality**:
    - Storing API keys, authentication tokens, and other private data in plain text could lead to data breaches. For instance, if someone were to gain access to the device, such data in `UserDefaults` could be easily extracted, whereas Keychain data remains encrypted.
    
 3. **Persistent Secure Storage**:
    - The Keychain allows you to store data persistently across app sessions and even device reboots, while ensuring that only authorized access is allowed. This is crucial for API keys or credentials that need to be available whenever the app is running, without the user needing to re-enter them.

 ### **What the Keychain Does:**

 1. **Encryption**:
    - The Keychain stores sensitive data in an encrypted format, using a combination of device-specific and user-specific factors to encrypt and decrypt this data. Even if the storage location is accessed, the information stored within it cannot be read without proper decryption.

 2. **Access Control**:
    - Only the app that added an item to the Keychain can retrieve it (unless you explicitly allow sharing between apps). This ensures that even if another app is installed on the same device, it cannot access the sensitive data stored by your app.

 3. **Security on Lock Screen**:
    - Keychain entries are protected based on the lock screen. If a device is locked and the data is configured to be accessible only when unlocked, the data remains secure until the device is unlocked.

 4. **APIs for Secure Management**:
    - The Keychain provides APIs for storing and retrieving data securely. For example, your code included:
      - **`SecItemAdd()`**: Adds a new item (such as an API key) to the Keychain.
      - **`SecItemCopyMatching()`**: Retrieves data from the Keychain (such as retrieving an API key for use).
      - **`SecItemDelete()`**: Removes an item from the Keychain.

 ### **How the Keychain Was Used in Your Code:**

 In your code, the Keychain was used to securely store several sensitive API keys, like `openAIKey`, `humeAIKey`, `anthropicAIKey`, etc. Here’s how it functioned:

 - **Storing Data**:
    - The API keys were saved to the Keychain using `KeychainHelper.save`. When you assigned a new key, it encrypted and securely stored the key.
    
 - **Retrieving Data**:
    - When an API key was needed, for example, `openAIKey`, the `KeychainHelper.read` function retrieved the encrypted key, decrypted it, and returned it for use.

 - **Ensuring Confidentiality**:
    - Using the Keychain for sensitive API keys ensured that even if someone gained access to the device, they couldn’t easily read or extract the API keys without going through the Keychain’s encryption.

 ---

 ### **In Short**:
 The **Keychain** was there to **securely store** sensitive API keys, tokens, or passwords and **protect them from unauthorized access**, leveraging encryption and access control. It was used to ensure that confidential data remains safe even if someone accesses the device or app storage directly. By removing the Keychain, you're reducing the complexity and security of your implementation, but in certain development contexts, this can be acceptable if you're prioritizing simplicity over security.
 */
