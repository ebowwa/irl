//
//  APIClient.swift
//
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//

import Foundation
import Combine

class ClaudeAPIClient {
    private let baseURL: URL
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.baseURL = URL(string: ClaudeConstants.API.baseURL)!
        self.session = session
    }

    func sendMessage(_ message: String, maxTokens: Int, model: String, temperature: Double, systemPrompt: String?) -> AnyPublisher<ClaudeResponse, Error> {
        let endpoint = baseURL.appendingPathComponent(ClaudeConstants.API.messagesEndpoint)
        let request = ClaudeRequest(
            maxTokens: maxTokens,
            messages: [ClaudeMessage(role: ClaudeConstants.MessageRoles.user, content: message)],
            model: model,
            stream: false,
            temperature: temperature,
            systemPrompt: systemPrompt?.isEmpty == false ? systemPrompt : nil
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
