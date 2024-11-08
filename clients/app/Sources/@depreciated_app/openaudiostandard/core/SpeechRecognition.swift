//
//  SpeechRecognition.swift
//  IRL
//
//  Created by Elijah Arbee on 10/25/24.
//

import Foundation
import Combine
import Speech
import AVFoundation

public class SpeechRecognitionManager: NSObject {
    // MARK: - Publishers
    @Published public private(set) var isSpeaking: Bool = false
    @Published public private(set) var transcription: String = ""
    @Published public private(set) var errorMessage: String?

    public var isSpeakingPublisher: AnyPublisher<Bool, Never> {
        $isSpeaking.eraseToAnyPublisher()
    }

    public var transcriptionPublisher: AnyPublisher<String, Never> {
        $transcription.eraseToAnyPublisher()
    }

    // MARK: - Properties
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var audioBufferSubscription: AnyCancellable?

    // MARK: - Initialization
    public init(locale: Locale = Locale(identifier: "en-US")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
        requestSpeechAuthorization()
    }

    // MARK: - Speech Recognition Authorization
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("[SpeechRecognitionManager] Speech recognition authorized.")
                case .denied, .restricted, .notDetermined:
                    print("[SpeechRecognitionManager] Speech recognition not authorized.")
                    self?.errorMessage = "Speech recognition not authorized."
                @unknown default:
                    print("[SpeechRecognitionManager] Unknown speech recognition authorization status.")
                    self?.errorMessage = "Unknown speech recognition authorization status."
                }
            }
        }
    }

    // MARK: - Start/Stop Speech Recognition
    public func startRecognition(audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never>) {
        guard recognitionTask == nil else {
            print("[SpeechRecognitionManager] Recognition task is already running.")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create a speech recognition request."
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognizer is not available."
            return
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                self.transcription = result.bestTranscription.formattedString
                self.isSpeaking = !result.isFinal
            }

            if let error = error {
                self.errorMessage = "Speech recognition error: \(error.localizedDescription)"
                self.isSpeaking = false
                self.recognitionTask = nil
            }

            if result?.isFinal == true {
                self.isSpeaking = false
                self.recognitionTask = nil
            }
        }

        // Subscribe to audio buffers
        audioBufferSubscription = audioBufferPublisher.sink { [weak self] buffer in
            self?.recognitionRequest?.append(buffer)
        }
    }

    public func stopRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        isSpeaking = false
        audioBufferSubscription?.cancel()
        audioBufferSubscription = nil
    }
}
