//
//  EmbeddingService.swift
//  irl
//
//  Created by Elijah Arbee on 9/18/24.
//
import Foundation

class EmbeddingService {
    static let shared = EmbeddingService()
    
    private init() {}
    
    func getEmbedding(for text: String, model: String = "small") async throws -> EmbeddingResponse {
        guard let url = URL(string: "\(Constants.API.baseURL)/embeddings/\(model)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["input_text": text]
        request.httpBody = try JSONEncoder().encode(body)
        
        print("Sending request to: \(url)")
        print("Request body: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("Received response with status code: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decodedResponse = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
        return decodedResponse
    }
}
