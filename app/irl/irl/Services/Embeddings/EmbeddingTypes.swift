//
//  EmbeddingTypes.swift
//  irl
//
//  Created by Elijah Arbee on 9/18/24.
//
// NOTE: Imported in EmbeddingView() **demo**
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

// TODO: ADD the following  into Memories; store alongside the the transcripts/memories?

// Metadata with context-aware details
struct ContextAwareMetadata: Codable {
    let original: EmbeddingMetadata
    let contextSensitive: Bool?              // Indicates whether the embedding is context-sensitive
    let multipleEmbeddings: Bool?            // If multiple embeddings are supported
    let generatedAt: Date?                   // When the embedding was generated
}

// Structure to capture different contexts for the word
struct WordContext: Codable {
    let contextId: String?                   // Unique identifier for the context (optional)
    let surroundingText: String?             // Text surrounding the word in this specific context (optional)
    let contextEmbedding: [Double]?          // Embedding vector for the word within this context (optional)
    let sentenceEmbedding: [Double]?         // Full sentence embedding for broader context (optional)
    let timestamp: Date?                     // Timestamp if embedding is dynamic (optional)
}

// Embedding response for a specific word with additional context
struct WordEmbeddingResponse: Codable {
    let original: EmbeddingResponse          // Original embedding response
    let word: String                         // The word or phrase being embedded (required)
    let contexts: [WordContext]?             // Multiple contexts for the word (optional)
    let enrichedMetadata: ContextAwareMetadata? // Context-sensitive metadata
}
