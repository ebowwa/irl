//
//  ClaudeTypes.swift
//  irl
//
//  Created by Elijah Arbee on 9/18/24.
//
import Foundation

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
