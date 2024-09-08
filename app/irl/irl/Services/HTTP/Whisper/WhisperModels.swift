//
//  WhisperModels.swift
//  irl
//
//  Created by Elijah Arbee on 9/8/24.
//
import Foundation

struct WhisperInput: Codable {
    let audio_url: String
    let task: TaskEnum
    let language: LanguageEnum
    var chunk_level: ChunkLevelEnum = .segment
    var version: VersionEnum = .v3
}

struct WhisperOutput: Codable {
    let text: String
    let chunks: [WhisperChunk]
}

struct WhisperChunk: Codable, Identifiable {
    var id = UUID()
    let timestamp: [Float]
    let text: String
}
