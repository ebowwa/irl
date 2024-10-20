//
//  SpeechLikelihoodAnalyzer.swift
//  irl
//
//  Created by Elijah Arbee on 9/7/24.
//

import Foundation
import Speech
import AVFoundation

enum SpeechAnalyzerError: Error, LocalizedError {
    case speechRecognizerUnavailable
    case audioFileNotAccessible
    case recognitionError(String)
    case noResultAvailable
    case authorizationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .speechRecognizerUnavailable:
            return "Speech recognizer is unavailable."
        case .audioFileNotAccessible:
            return "Audio file is not accessible."
        case .recognitionError(let message):
            return "Recognition error: \(message)"
        case .noResultAvailable:
            return "No recognition result available."
        case .authorizationFailed(let message):
            return "Authorization failed: \(message)"
        }
    }
}

class SpeechLikelihoodAnalyzer {
    private let speechRecognizer: SFSpeechRecognizer?

    init(locale: Locale = Locale(identifier: "en-US")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    // Request speech recognition authorization with a clearer completion handler
    func requestSpeechAuthorization(completion: @escaping (Result<Bool, SpeechAnalyzerError>) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    completion(.success(true))
                case .denied, .restricted, .notDetermined:
                    let errorDescription = "Authorization failed with status: \(authStatus.rawValue)"
                    print(errorDescription)
                    completion(.failure(.authorizationFailed(errorDescription)))
                @unknown default:
                    print("Unknown authorization status.")
                    completion(.failure(.authorizationFailed("Unknown authorization status.")))
                }
            }
        }
    }

    // Analyze if an audio file contains speech, simplified completion logic
    func determineSpeechLikelihood(for url: URL, completion: @escaping (Result<Bool, SpeechAnalyzerError>) -> Void) {
        guard let recognizer = speechRecognizer else {
            completion(.failure(.speechRecognizerUnavailable))
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                completion(.failure(.recognitionError(error.localizedDescription)))
                return
            }

            guard let result = result else {
                completion(.failure(.noResultAvailable))
                return
            }

            let isSpeechLikely = self.evaluateSpeechLikelihood(result)
            completion(.success(isSpeechLikely))
        }
    }

    // Analyze live audio buffer for speech likelihood, reducing redundancy in completion logic
    func determineSpeechLikelihood(from buffer: AVAudioPCMBuffer, completion: @escaping (Result<Bool, SpeechAnalyzerError>) -> Void) {
        guard let recognizer = speechRecognizer else {
            completion(.failure(.speechRecognizerUnavailable))
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.append(buffer)

        recognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                completion(.failure(.recognitionError(error.localizedDescription)))
                return
            }

            guard let result = result else {
                completion(.failure(.noResultAvailable))
                return
            }

            let isSpeechLikely = self.evaluateSpeechLikelihood(result)
            completion(.success(isSpeechLikely))
        }
    }

    // Helper function to evaluate speech likelihood
    private func evaluateSpeechLikelihood(_ result: SFSpeechRecognitionResult) -> Bool {
        let wordCount = result.bestTranscription.formattedString.split(separator: " ").count
        let confidence = result.bestTranscription.segments.first?.confidence ?? 0
        return wordCount > 1 && confidence > 0.5
    }
}
