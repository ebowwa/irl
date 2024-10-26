//
//  envKeys.swift
//  ProjectIRL
//
//  Created by Elijah Arbee on 10/8/24.
//

import Foundation

struct ConstantAPIKeys {
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
