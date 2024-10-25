//
//  TranscriptionManager.swift
//  IRL
//
//  Created by Elijah Arbee on 10/25/24.
//

import Foundation
import Combine

public class TranscriptionManager: ObservableObject {
    // Singleton instance
    public static let shared = TranscriptionManager()
    
    // Published properties
    @Published private(set) var transcriptionHistory: [String] = []
    @Published private(set) var lastTranscribedText: String = ""
    
    // Private properties
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Listen to transcription updates from RecordingScript
        RecordingScript.shared.transcriptionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcription in
                self?.handleTranscription(transcription)
            }
            .store(in: &cancellables)
    }
    
    // Handle incoming transcriptions
    private func handleTranscription(_ transcription: String) {
        // If the transcription is final, add it to history
        if RecordingScript.shared.isFinalTranscription {
            if !transcription.isEmpty {
                transcriptionHistory.append(transcription)
                lastTranscribedText = ""
            }
        } else {
            // Update the latest transcription
            lastTranscribedText = transcription
        }
    }
    
    // Public methods to access transcriptions
    public func getTranscriptionHistory() -> [String] {
        return transcriptionHistory
    }
    
    public func getLastTranscribedText() -> String {
        return lastTranscribedText
    }
    
    // Optional: Methods to persist transcriptions
    public func saveTranscriptions() {
        // Implement persistence logic (e.g., save to UserDefaults, file, or database)
    }
    
    public func loadTranscriptions() {
        // Implement loading logic
    }
}
