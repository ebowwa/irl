//
//  Model.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import Foundation
import Combine
import SwiftUI

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeContentItem: Codable {
    let text: String
    let type: String
}

struct ClaudeUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

struct ClaudeResponse: Codable {
    let content: String
    let usage: ClaudeUsage
}

struct ClaudeRequest: Codable {
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let model: String
    let stream: Bool
    let temperature: Double
    let systemPrompt: String?
    enum CodingKeys: String, CodingKey {
        case maxTokens = "max_tokens"
        case messages, model, stream, temperature
        case systemPrompt = "system"
    }
}

class ClaudeViewModel: ObservableObject {
    @Published var response: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: "selectedModel") }
    }
    @Published var maxTokens: Int {
        didSet { UserDefaults.standard.set(maxTokens, forKey: "maxTokens") }
    }
    @Published var temperature: Double {
        didSet { UserDefaults.standard.set(temperature, forKey: "temperature") }
    }
    @Published var systemPrompt: String {
        didSet { UserDefaults.standard.set(systemPrompt, forKey: "systemPrompt") }
    }
    @Published private(set) var currentConfiguration: Configuration?

    static let availableModels = ["claude-3-haiku-20240307", "claude-3-sonnet-20240229", "claude-3-opus-20240229"]
    private let apiClient: ClaudeAPIClient
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: ClaudeAPIClient) {
        self.apiClient = apiClient
        self.model = UserDefaults.standard.string(forKey: "selectedModel") ?? ClaudeConstants.DefaultParams.model
        self.maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
        self.temperature = UserDefaults.standard.double(forKey: "temperature")
        self.systemPrompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? ""
        if self.maxTokens == 0 { self.maxTokens = ClaudeConstants.DefaultParams.maxTokens }
        if self.temperature == 0 { self.temperature = 0.7 } // Default temperature
    }

    func sendMessage(_ message: String) {
        isLoading = true
        error = nil
        response = "" // Clear previous response

        let modelToUse = currentConfiguration?.parameters.model ?? model
        let maxTokensToUse = currentConfiguration?.parameters.maxTokens ?? maxTokens
        let temperatureToUse = currentConfiguration?.parameters.temperature ?? temperature
        let systemPromptToUse = currentConfiguration?.parameters.systemPrompt ?? systemPrompt

        apiClient.sendMessage(message, maxTokens: maxTokensToUse, model: modelToUse, temperature: temperatureToUse, systemPrompt: systemPromptToUse)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.response = response.content
            }
            .store(in: &cancellables)
    }

    func setConfiguration(_ configuration: Configuration) {
        currentConfiguration = configuration
        // Update the current settings to match the configuration
        model = configuration.parameters.model
        maxTokens = configuration.parameters.maxTokens
        temperature = configuration.parameters.temperature
        systemPrompt = configuration.parameters.systemPrompt
    }

    func clearConfiguration() {
        currentConfiguration = nil
        // Reset to default values or load from UserDefaults as needed
        model = UserDefaults.standard.string(forKey: "selectedModel") ?? ClaudeConstants.DefaultParams.model
        maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
        temperature = UserDefaults.standard.double(forKey: "temperature")
        systemPrompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? ""
    }
}
