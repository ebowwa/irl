//
//  SpeechRecognition.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/23/24.
//

import Foundation
import Speech
import Combine
import AVFoundation

// MARK: - SpeechAuthorizationManager

public class SpeechAuthorizationManager: ObservableObject {
    @Published public var isAuthorized: Bool = false

    public static let shared = SpeechAuthorizationManager()

    private init() {
        requestAuthorization()
    }

    public func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                self?.isAuthorized = (authStatus == .authorized)
                if !(self?.isAuthorized ?? false) {
                    print("Speech recognition authorization denied.")
                } else {
                    print("Speech recognition authorized.")
                }
            }
        }
    }
}

// MARK: - SpeechRecognitionManager

public class SpeechRecognitionManager: ObservableObject {
    // MARK: - Shared Instance
    public static let shared = SpeechRecognitionManager()
    
    // MARK: - Dependencies
    private let authorizationManager = SpeechAuthorizationManager.shared
    private let audioEngineManager = AudioEngineManager.shared
    
    // MARK: - Speech Recognition Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // MARK: - Published Properties
    @Published public var transcribedText: String = "Transcribed text will appear here."
    @Published public var isSpeechDetected: Bool = false
    
    // MARK: - Callbacks
    public var onSpeechStart: (() -> Void)?
    public var onSpeechEnd: (() -> Void)?
    
    // MARK: - Combine Subscriptions
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Initialization
    private init() {
        setupSpeechRecognizer()
        setupAuthorizationBinding()
    }
    
    // MARK: - Setup Methods
    
    /// Configures the speech recognizer with the desired locale.
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    /// Sets up bindings to observe authorization status changes.
    private func setupAuthorizationBinding() {
        authorizationManager.$isAuthorized
            .sink { [weak self] isAuthorized in
                if isAuthorized {
                    self?.startRecognition()
                } else {
                    self?.transcribedText = "Speech recognition not authorized."
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Speech Recognition Control
    
    /// Starts the speech recognition process.
    public func startRecognition() {
        guard authorizationManager.isAuthorized else {
            print("SpeechRecognitionManager: Not authorized to start recognition.")
            return
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("SpeechRecognitionManager: Speech recognizer is not available.")
            transcribedText = "Speech recognizer is not available."
            return
        }
        
        // Initialize the recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("SpeechRecognitionManager: Unable to create an SFSpeechAudioBufferRecognitionRequest object.")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true
        
        // Start the recognition task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                    self.handleSpeechDetection(from: result.bestTranscription)
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecognition()
            }
        }
        
        // Subscribe to audio buffers and append them to the recognition request
        audioEngineManager.audioBufferPublisher
            .sink { [weak self] buffer in
                self?.recognitionRequest?.append(buffer)
            }
            .store(in: &cancellables)
        
        // Start the audio engine
        audioEngineManager.startEngine()
    }
    
    /// Stops the speech recognition process.
    public func stopRecognition() {
        audioEngineManager.stopEngine()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
    
    // MARK: - Speech Detection Handling
    
    /// Handles the detection of speech based on the current transcription.
    /// - Parameter transcription: The latest transcription result.
    private func handleSpeechDetection(from transcription: SFTranscription) {
        let currentText = transcription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
        let wasSpeechDetected = isSpeechDetected
        isSpeechDetected = !currentText.isEmpty
        
        if isSpeechDetected && !wasSpeechDetected {
            onSpeechStart?()
        } else if !isSpeechDetected && wasSpeechDetected {
            onSpeechEnd?()
        }
    }
    
    // MARK: - Additional Functionalities
    
    /// Determines if the audio file contains speech.
    /// - Parameters:
    ///   - url: URL of the audio file to analyze.
    ///   - completion: Closure called with the result (true if speech is likely, false otherwise).
    public func determineSpeechLikelihood(for url: URL, completion: @escaping (Bool) -> Void) {
        guard let recognizer = speechRecognizer else {
            completion(false)
            return
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer.recognitionTask(with: request) { result, error in
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
}
