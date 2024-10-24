// ARecordingModel.swift
// openaudiostandard
//
// Created by Elijah Arbee on 10/23/24.
//

import Foundation

public struct AudioRecording: Identifiable {
    public let id: UUID
    public let url: URL
    public var isSpeechLikely: Bool?
    
    public init(id: UUID = UUID(), url: URL, isSpeechLikely: Bool? = nil) {
        self.id = id
        self.url = url
        self.isSpeechLikely = isSpeechLikely
    }
}

