//
//  SpeechRecognition.swift
//  IRL-AudioCore
//
//  Created by Elijah Arbee on 9/6/24.
//

import Foundation
import Speech
import Combine
import AVFoundation

// MARK: - Constants
private enum SpeechRecognitionConstants {
    static let locale = Locale(identifier: "en-US")
    static let calibrationCooldown: TimeInterval = 60.0
}

// MARK: - SpeechRecognitionManager

public class SpeechRecognitionManager: ObservableObject {
    public static let shared = SpeechRecognitionManager()
    
    // Reference to AudioEngineManagerProtocol
    private let audioEngineManager: AudioEngineManagerProtocol
    
    // MARK: - Published Properties
    @Published public var transcribedText = "Transcribed text will appear here."
    @Published public var transcriptionSegments: [String] = []
    @Published public var isSpeechDetected: Bool = false
    @Published public var speechMetadata: [String: Any] = [:]
    
    // **New Published Property for Authorization Status**
    @Published public var isAuthorized: Bool = false
    
    // MARK: - Speech Detection Callbacks
    public var onSpeechStart: (() -> Void)?
    public var onSpeechEnd: (() -> Void)?
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: SpeechRecognitionConstants.locale)!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var lastTranscription: String = ""
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Streamed Properties
    private let maxSegmentCount = 10
    
    // MARK: - Initialization
    
    public init(audioEngineManager: AudioEngineManagerProtocol = AudioEngineManager.shared) {
        self.audioEngineManager = audioEngineManager
    }
    
    // MARK: - Speech Authorization Request
    
    /// Requests speech recognition authorization.
    public func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                self?.handleAuthorizationStatus(authStatus)
            }
        }
    }
    
    private func handleAuthorizationStatus(_ authStatus: SFSpeechRecognizerAuthorizationStatus) {
        switch authStatus {
        case .authorized:
            isAuthorized = true
        case .denied, .restricted, .notDetermined:
            isAuthorized = false
            transcribedText = "Speech recognition not authorized."
        @unknown default:
            isAuthorized = false
            transcribedText = "Unknown authorization status."
        }
    }
    
    // MARK: - Recording Control
    
    /// Starts the speech recognition recording.
    public func startRecording() {
        guard !audioEngineManager.isEngineRunning else { return }
        resetRecognitionTask()
        setupSpeechRecognition()
        subscribeToAudioBuffers()
        audioEngineManager.startEngine()
    }
    
    /// Stops the speech recognition recording.
    public func stopRecording() {
        if audioEngineManager.isEngineRunning {
            audioEngineManager.stopEngine()
            recognitionRequest?.endAudio()
        }
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    // MARK: - Recognition Task Reset
    
    private func resetRecognitionTask() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    // MARK: - Speech Recognition Setup
    
    private func setupSpeechRecognition() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        // **Ensure On-Device Recognition is Enabled**
        recognitionRequest?.requiresOnDeviceRecognition = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            self?.handleStreamingResult(result, error)
        }
    }
    
    // MARK: - Streaming Transcription Handling
    
    private func handleStreamingResult(_ result: SFSpeechRecognitionResult?, _ error: Error?) {
        guard let result = result else { return }
        DispatchQueue.main.async {
            self.transcribedText = result.bestTranscription.formattedString
            self.updateTranscriptionSegments(from: result.bestTranscription)
            
            // Detect speech start and end
            let currentText = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
            let wasSpeechDetected = self.isSpeechDetected
            self.isSpeechDetected = !currentText.isEmpty
            
            if self.isSpeechDetected && !wasSpeechDetected {
                self.onSpeechStart?()
            } else if !self.isSpeechDetected && wasSpeechDetected {
                self.onSpeechEnd?()
            }
            
            self.speechMetadata = [
                "isFinal": result.isFinal,
                "confidence": result.bestTranscription.segments.last?.confidence ?? 0.0,
                "formattedStringLength": result.bestTranscription.formattedString.count
            ]
        }
        if error != nil || result.isFinal {
            stopRecording()
        }
    }
    
    // MARK: - Transcription Segments Streaming Update
    
    private func updateTranscriptionSegments(from transcription: SFTranscription) {
        let newSegments = transcription.segments.dropFirst(transcriptionSegments.count)
        newSegments.forEach { segment in
            let start = transcription.formattedString.index(transcription.formattedString.startIndex, offsetBy: segment.substringRange.location)
            let end = transcription.formattedString.index(start, offsetBy: segment.substringRange.length)
            let substring = String(transcription.formattedString[start..<end])
            
            transcriptionSegments.append(substring)
            if transcriptionSegments.count > maxSegmentCount {
                transcriptionSegments.removeFirst()
            }
        }
    }
    
    /// Determines if the audio file contains speech.
    public func determineSpeechLikelihood(for url: URL, completion: @escaping (Bool) -> Void) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        speechRecognizer.recognitionTask(with: request) { result, error in
            if let _ = error {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            guard let result = result else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Analyze the speech transcription result and confidence to determine if speech is present.
            let isSpeechLikely = result.bestTranscription.formattedString.split(separator: " ").count > 1 &&
                (result.bestTranscription.segments.last?.confidence ?? 0 > 0.5)
            DispatchQueue.main.async {
                completion(isSpeechLikely)
            }
        }
    }
    
    // MARK: - Audio Buffer Subscription
    
    private func subscribeToAudioBuffers() {
        audioEngineManager.audioBufferPublisher
            .sink { [weak self] buffer in
                self?.recognitionRequest?.append(buffer)
            }
            .store(in: &cancellables)
    }
}
