//
//  ClaudeViewModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/28/24.
//
//  This file defines the ClaudeViewModel, which manages the state and interactions with the Claude API.
//  It handles sending messages, receiving responses, and managing configurations.
//

import Foundation
import Combine
import SwiftUI

// MARK: - ClaudeViewModel

/// ViewModel for managing interactions with the Claude API.
class ClaudeViewModel: ObservableObject {
    // MARK: Published Properties
    
    @Published var response: String = "" // The latest response from the API.
    @Published var isLoading: Bool = false // Indicates if a request is in progress.
    @Published var error: String? // Holds any error messages.
    
    @Published var model: String {
        didSet { saveConfiguration() } // Save configuration whenever the model changes.
    }
    @Published var maxTokens: Int {
        didSet { saveConfiguration() } // Save configuration whenever maxTokens changes.
    }
    @Published var temperature: Double {
        didSet { saveConfiguration() } // Save configuration whenever temperature changes.
    }
    @Published var systemPrompt: String {
        didSet { saveConfiguration() } // Save configuration whenever systemPrompt changes.
    }
    
    @Published private(set) var currentConfiguration: Configuration? // The currently applied configuration.
    
    // MARK: Private Properties
    
    private let apiClient: ClaudeAPIClient // Client for interacting with the Claude API.
    private var cancellables = Set<AnyCancellable>() // Set to hold Combine cancellables.
    
    // MARK: Initializer
    
    /// Initializes the ViewModel with a given API client.
    /// - Parameter apiClient: The ClaudeAPIClient to use for API interactions.
    init(apiClient: ClaudeAPIClient) {
        self.apiClient = apiClient
        self.model = ClaudeConstants.DefaultParams.model
        self.maxTokens = ClaudeConstants.DefaultParams.maxTokens
        self.temperature = 0.7
        self.systemPrompt = ""
        loadDefaults() // Load default settings from UserDefaults.
    }
    
    // MARK: Configuration Persistence
    
    /// Loads default configuration settings from UserDefaults.
    func loadDefaults() {
        model = UserDefaults.standard.string(forKey: "selectedModel") ?? ClaudeConstants.DefaultParams.model
        maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
        if maxTokens == 0 { maxTokens = ClaudeConstants.DefaultParams.maxTokens }
        
        temperature = UserDefaults.standard.double(forKey: "temperature")
        if temperature == 0 { temperature = 0.7 }
        
        systemPrompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? ""
    }
    
    /// Saves the current configuration settings to UserDefaults.
    func saveConfiguration() {
        UserDefaults.standard.set(model, forKey: "selectedModel")
        UserDefaults.standard.set(maxTokens, forKey: "maxTokens")
        UserDefaults.standard.set(temperature, forKey: "temperature")
        UserDefaults.standard.set(systemPrompt, forKey: "systemPrompt")
    }
    
    /// Retrieves the effective parameters, considering any applied configurations.
    /// - Returns: A tuple containing model, maxTokens, temperature, and systemPrompt.
    func getEffectiveParameters() -> (String, Int, Double, String?) {
        return (
            currentConfiguration?.parameters.model ?? model,
            currentConfiguration?.parameters.maxTokens ?? maxTokens,
            currentConfiguration?.parameters.temperature ?? temperature,
            currentConfiguration?.parameters.systemPrompt ?? systemPrompt
        )
    }
    
    // MARK: API Interaction
    
    /**
     Sends a message to the Claude API.
     
     - Parameters:
        - chatMessage: The message to send.
        - completion: A closure that is called with a Bool indicating success or failure.
     
     - Note:
        - This method does not set `isLoading` as each message manages its own sending state.
        - Resets the previous response and error before sending a new message.
     */
    func sendMessage(_ chatMessage: ChatMessageObservable, completion: @escaping (Bool) -> Void) {
        error = nil
        response = "" // Clear previous response.
        
        let (modelToUse, maxTokensToUse, temperatureToUse, systemPromptToUse) = getEffectiveParameters()
        
        // Initiate the API request.
        apiClient.sendMessage(
            chatMessage.content,
            maxTokens: maxTokensToUse,
            model: Constants.AI_MODELS.apiModel(for: modelToUse) ?? modelToUse,
            temperature: temperatureToUse,
            systemPrompt: systemPromptToUse
        )
        .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread.
        .sink(receiveCompletion: { [weak self] (completionResult: Subscribers.Completion<Error>) in
            switch completionResult {
            case .failure(let error):
                self?.error = error.localizedDescription
                completion(false) // Indicate failure.
            case .finished:
                break
            }
        }, receiveValue: { [weak self] (response: ClaudeResponse) in
            self?.response = response.content
            completion(true) // Indicate success.
        })
        .store(in: &cancellables) // Store the cancellable to manage its lifecycle.
    }
    
    // MARK: Configuration Management
    
    /// Applies a given configuration to the ViewModel.
    /// - Parameter configuration: The Configuration to apply.
    func setConfiguration(_ configuration: Configuration) {
        currentConfiguration = configuration
        model = configuration.parameters.model
        maxTokens = configuration.parameters.maxTokens
        temperature = configuration.parameters.temperature
        systemPrompt = configuration.parameters.systemPrompt
    }
    
    /// Clears the current configuration and reloads default settings.
    func clearConfiguration() {
        currentConfiguration = nil
        loadDefaults()
    }
}
