//
//  ClaudeSupport.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import Foundation
import Combine
import SwiftUI

// MARK: - Constants

struct ClaudeConstants {
    struct API {
        static let baseURL = "https://api.anthropic.com"
        static let messagesEndpoint = "/v1/messages"
    }
    
    struct MessageRoles {
        static let user = "user"
        static let assistant = "assistant"
    }
    
    struct ContentTypes {
        static let text = "text"
    }
    
    struct DefaultParams {
        static let maxTokens = 50
        static let model = "claude-3-haiku-20240307"
    }
    
    struct HTTPHeaders {
        static let contentTypeKey = "Content-Type"
        static let contentTypeValue = "application/json"
    }
}

// MARK: - Models

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeRequest: Codable {
    let maxTokens: Int
    let messages: [ClaudeMessage]
    let model: String
    let stream: Bool
    
    enum CodingKeys: String, CodingKey {
        case maxTokens = "max_tokens"
        case messages, model, stream
    }
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
    let content: [ClaudeContentItem]
    let usage: ClaudeUsage
}

// MARK: - API Client

class ClaudeAPIClient {
    private let baseURL: URL
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.baseURL = URL(string: ClaudeConstants.API.baseURL)!
        self.session = session
    }
    
    func sendMessage(_ message: String, maxTokens: Int = ClaudeConstants.DefaultParams.maxTokens, model: String = ClaudeConstants.DefaultParams.model) -> AnyPublisher<ClaudeResponse, Error> {
        let endpoint = baseURL.appendingPathComponent(ClaudeConstants.API.messagesEndpoint)
        
        let request = ClaudeRequest(
            maxTokens: maxTokens,
            messages: [ClaudeMessage(role: ClaudeConstants.MessageRoles.user, content: message)],
            model: model,
            stream: false
        )
        
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(ClaudeConstants.HTTPHeaders.contentTypeValue, forHTTPHeaderField: ClaudeConstants.HTTPHeaders.contentTypeKey)
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: ClaudeResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

// MARK: - View Model

class ClaudeViewModel: ObservableObject {
    @Published var response: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let apiClient: ClaudeAPIClient
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: ClaudeAPIClient) {
        self.apiClient = apiClient
    }
    
    func sendMessage(_ message: String) {
        isLoading = true
        error = nil
        
        apiClient.sendMessage(message)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.error = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.response = response.content.first?.text ?? "No response"
            }
            .store(in: &cancellables)
    }
}
