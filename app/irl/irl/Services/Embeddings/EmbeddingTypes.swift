//
//  EmbeddingTypes.swift
//  irl
//
//  Created by Elijah Arbee on 9/18/24.
//
import Foundation

struct EmbeddingResponse: Codable {
    let embedding: [Double]
    let metadata: EmbeddingMetadata
}

struct EmbeddingMetadata: Codable {
    let model: String
    let dimensions: Int
    let token_count: Int
    let input_char_count: Int
    let normalized: Bool
}
