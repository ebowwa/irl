//
//  LiveViewTranscriptModel.swift
//  IRL
//
//  Created by Elijah Arbee on 10/10/24.
//

// Models/TranscriptMessage.swift

import Foundation

/// Represents a single transcript message in the dialogue.
struct TranscriptMessage: Identifiable, Codable {
    let id = UUID() // Unique identifier for ForEach
    let speaker: String
    let message: String
    let timestamp: String
}
