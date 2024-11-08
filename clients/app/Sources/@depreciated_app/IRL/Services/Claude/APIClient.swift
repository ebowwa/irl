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

    func createRequest(for endpoint: URL, body: Data) -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(ClaudeConstants.HTTPHeaders.contentTypeValue, forHTTPHeaderField: ClaudeConstants.HTTPHeaders.contentTypeKey)
        request.httpBody = body
        return request
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
        do {
            let urlRequest = createRequest(for: endpoint, body: try JSONEncoder().encode(request))
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
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
