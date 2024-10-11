//
//  AIModelDefinitions.swift
//  ProjectIRL
//
//  Created by Elijah Arbee on 10/8/24.

import Foundation

struct ConstantAIModels {
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
