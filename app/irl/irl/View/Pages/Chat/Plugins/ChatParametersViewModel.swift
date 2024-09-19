//
//  ChatParametersViewModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
// TODO: don't ask the user to save the Config as anything if unchanged from default, also maybe we should modularize the dollowing to isomorphize the saved config from the ui so we can also load older configs and different configs
import SwiftUI
import CoreData

class ChatParametersViewModel: ObservableObject, Codable {
    @Published var personality: String = ""
    @Published var skills: String = ""
    @Published var learningObjectives: String = ""
    @Published var intendedBehaviors: String = ""
    @Published var specificNeeds: String = ""
    @Published var apiEndpoint: String = ""
    @Published var jsonSchema: String = ""
    
    @Published var model: String
    @Published var maxTokens: Int
    @Published var temperature: Double
    @Published var systemPrompt: String
    
    @Published var imageGenerationEnabled: Bool = false
    @Published var speechGenerationEnabled: Bool = false
    @Published var videoGenerationEnabled: Bool = false
    
    @Published var useAIAlignment: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case personality, skills, learningObjectives, intendedBehaviors, specificNeeds, apiEndpoint, jsonSchema
        case model, maxTokens, temperature, systemPrompt
        case imageGenerationEnabled, speechGenerationEnabled, videoGenerationEnabled
        case useAIAlignment
    }
    
    init(claudeViewModel: ClaudeViewModel) {
        self.model = claudeViewModel.model
        self.maxTokens = claudeViewModel.maxTokens
        self.temperature = claudeViewModel.temperature
        self.systemPrompt = claudeViewModel.systemPrompt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        personality = try container.decode(String.self, forKey: .personality)
        skills = try container.decode(String.self, forKey: .skills)
        learningObjectives = try container.decode(String.self, forKey: .learningObjectives)
        intendedBehaviors = try container.decode(String.self, forKey: .intendedBehaviors)
        specificNeeds = try container.decode(String.self, forKey: .specificNeeds)
        apiEndpoint = try container.decode(String.self, forKey: .apiEndpoint)
        jsonSchema = try container.decode(String.self, forKey: .jsonSchema)
        model = try container.decode(String.self, forKey: .model)
        maxTokens = try container.decode(Int.self, forKey: .maxTokens)
        temperature = try container.decode(Double.self, forKey: .temperature)
        systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
        imageGenerationEnabled = try container.decode(Bool.self, forKey: .imageGenerationEnabled)
        speechGenerationEnabled = try container.decode(Bool.self, forKey: .speechGenerationEnabled)
        videoGenerationEnabled = try container.decode(Bool.self, forKey: .videoGenerationEnabled)
        useAIAlignment = try container.decode(Bool.self, forKey: .useAIAlignment)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(personality, forKey: .personality)
        try container.encode(skills, forKey: .skills)
        try container.encode(learningObjectives, forKey: .learningObjectives)
        try container.encode(intendedBehaviors, forKey: .intendedBehaviors)
        try container.encode(specificNeeds, forKey: .specificNeeds)
        try container.encode(apiEndpoint, forKey: .apiEndpoint)
        try container.encode(jsonSchema, forKey: .jsonSchema)
        try container.encode(model, forKey: .model)
        try container.encode(maxTokens, forKey: .maxTokens)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(systemPrompt, forKey: .systemPrompt)
        try container.encode(imageGenerationEnabled, forKey: .imageGenerationEnabled)
        try container.encode(speechGenerationEnabled, forKey: .speechGenerationEnabled)
        try container.encode(videoGenerationEnabled, forKey: .videoGenerationEnabled)
        try container.encode(useAIAlignment, forKey: .useAIAlignment)
    }
    
    func applyToClaudeViewModel(_ claudeViewModel: ClaudeViewModel) {
        claudeViewModel.model = self.model
        claudeViewModel.maxTokens = self.maxTokens
        claudeViewModel.temperature = self.temperature
        claudeViewModel.systemPrompt = self.systemPrompt
        // are we missing any other properties?
    }
}
