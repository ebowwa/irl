//
//  Model.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import Foundation
import Combine
import SwiftUI

class ClaudeViewModel: ObservableObject {
    @Published var response: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var model: String {
        didSet { saveConfiguration() }
    }
    @Published var maxTokens: Int {
        didSet { saveConfiguration() }
    }
    @Published var temperature: Double {
        didSet { saveConfiguration() }
    }
    @Published var systemPrompt: String {
        didSet { saveConfiguration() }
    }
    @Published private(set) var currentConfiguration: Configuration?

    private let apiClient: ClaudeAPIClient
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: ClaudeAPIClient) {
        self.apiClient = apiClient
        self.model = ClaudeConstants.DefaultParams.model
        self.maxTokens = ClaudeConstants.DefaultParams.maxTokens
        self.temperature = 0.7
        self.systemPrompt = ""
        loadDefaults()
    }

    func loadDefaults() {
        model = UserDefaults.standard.string(forKey: "selectedModel") ?? ClaudeConstants.DefaultParams.model
        maxTokens = UserDefaults.standard.integer(forKey: "maxTokens")
        if maxTokens == 0 { maxTokens = ClaudeConstants.DefaultParams.maxTokens }

        temperature = UserDefaults.standard.double(forKey: "temperature")
        if temperature == 0 { temperature = 0.7 }

        systemPrompt = UserDefaults.standard.string(forKey: "systemPrompt") ?? ""
    }

    func saveConfiguration() {
        UserDefaults.standard.set(model, forKey: "selectedModel")
        UserDefaults.standard.set(maxTokens, forKey: "maxTokens")
        UserDefaults.standard.set(temperature, forKey: "temperature")
        UserDefaults.standard.set(systemPrompt, forKey: "systemPrompt")
    }

    func getEffectiveParameters() -> (String, Int, Double, String?) {
        return (
            currentConfiguration?.parameters.model ?? model,
            currentConfiguration?.parameters.maxTokens ?? maxTokens,
            currentConfiguration?.parameters.temperature ?? temperature,
            currentConfiguration?.parameters.systemPrompt ?? systemPrompt
        )
    }

    func sendMessage(_ message: String) {
        isLoading = true
        error = nil
        response = ""  // Clear previous response

        let (modelToUse, maxTokensToUse, temperatureToUse, systemPromptToUse) = getEffectiveParameters()

        apiClient.sendMessage(message, maxTokens: maxTokensToUse, model: Constants.AI_MODELS.apiModel(for: modelToUse) ?? modelToUse, temperature: temperatureToUse, systemPrompt: systemPromptToUse)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.error = error.localizedDescription
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] (response: ClaudeResponse) in
                self?.response = response.content
            })
            .store(in: &cancellables)
    }

    func setConfiguration(_ configuration: Configuration) {
        currentConfiguration = configuration
        model = configuration.parameters.model
        maxTokens = configuration.parameters.maxTokens
        temperature = configuration.parameters.temperature
        systemPrompt = configuration.parameters.systemPrompt
    }

    func clearConfiguration() {
        currentConfiguration = nil
        loadDefaults()
    }
}
