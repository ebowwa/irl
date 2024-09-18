//
//  SpeechAnalysisService.swift
//  This service handles speech analysis, including detecting if audio files are worth sending for transcription and prosody analysis.
//  It also manages a queue of audio files ready for analysis and provides an on/off widget for user control.
//
//  Created by Elijah Arbee on 8/30/24.
// TODO: correct analysis result, currently will determine, but often will need a full page refresh to change state and if no speech is detected it will still say analyzing not no speech detected
//
import Foundation
import Speech

// Ensure the service is available on iOS 17.0 and later
@available(iOS 17.0, *)
class SpeechAnalysisService: NSObject, ObservableObject, SFSpeechRecognitionTaskDelegate {
    static let shared = SpeechAnalysisService()

    @Published var analysisProbabilities: [URL: Double] = [:]
    @Published var isAnalyzing: Bool = false
    @Published var errorMessage: String?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentRecordingURL: URL?
    private let analysisQueue = DispatchQueue(label: "com.yourapp.speechAnalysis", qos: .userInitiated)

    private override init() {
        super.init()
        setupSpeechRecognizer()
    }

    private func setupSpeechRecognizer() {
        self.speechRecognizer = SFSpeechRecognizer()
        self.speechRecognizer?.delegate = self
        checkSpeechRecognitionPermission()
    }

    // Setup language model for speech recognition
    private func setupLanguageModel() {
        if let locale = speechRecognizer?.locale {
            print("Speech recognizer initialized with locale: \(locale.identifier)")
        } else {
            print("Speech recognizer locale not available")
        }
    }

    // Method to change language
    func changeLanguage(to identifier: String) {
        guard let newRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier)) else {
            print("Failed to create speech recognizer for locale: \(identifier)")
            return
        }
        
        DispatchQueue.main.async {
            self.speechRecognizer?.delegate = nil  // Remove delegate from old recognizer
            self.speechRecognizer = newRecognizer
            self.speechRecognizer?.delegate = self
            print("Changed speech recognizer to locale: \(identifier)")
            self.setupLanguageModel()  // Reinitialize the language model
        }
    }

    // Check and request speech recognition permission
    func checkSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                    self.setupLanguageModel()
                case .denied:
                    self.errorMessage = "Speech recognition permission denied"
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted on this device"
                case .notDetermined:
                    self.errorMessage = "Speech recognition permission not determined"
                @unknown default:
                    self.errorMessage = "Unknown speech recognition authorization status"
                }
            }
        }
    }

    // Analyze a single audio recording
    func analyzeRecording(_ recording: AudioRecording) async {
        guard authorizationStatus == .authorized else {
            await MainActor.run {
                errorMessage = "Speech recognition is not authorized"
                isAnalyzing = false
            }
            return
        }

        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
            currentRecordingURL = recording.url
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            await MainActor.run {
                errorMessage = "Speech recognition is not available"
                isAnalyzing = false
            }
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: recording.url)

        do {
            let result: SFSpeechRecognitionResult = try await withCheckedThrowingContinuation { continuation in
                recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let result = result, result.isFinal {
                        continuation.resume(returning: result)
                    }
                }
            }
            await processResult(result)
        } catch {
            await MainActor.run {
                errorMessage = "Speech recognition failed: \(error.localizedDescription)"
                isAnalyzing = false
            }
        }
    }

    // Analyze multiple audio recordings
    func analyzeAllRecordings(_ recordings: [AudioRecording]) async {
        for recording in recordings {
            await analyzeRecording(recording)
        }
    }

    // Process the result of a speech recognition task
    private func processResult(_ result: SFSpeechRecognitionResult) async {
        let wordCount = result.bestTranscription.segments.reduce(into: 0) { $0 += $1.substring.split(separator: " ").count }
        let durationInSeconds = result.bestTranscription.segments.last?.duration ?? 0

        // Assume an average speaking rate of 2 words per second
        let expectedWordCount = durationInSeconds * 2

        // Calculate percentage, capping at 100%
        let percentage = min((Double(wordCount) / expectedWordCount) * 100, 100)

        await MainActor.run {
            guard let currentURL = self.currentRecordingURL else { return }
            self.analysisProbabilities[currentURL] = percentage
            self.isAnalyzing = false
        }
    }

    // Cancel any ongoing speech recognition tasks
    func cancelOngoingTasks() {
        recognitionTask?.cancel()
        recognitionTask = nil
        isAnalyzing = false
    }
}

// Conform to SFSpeechRecognizerDelegate to handle changes in availability
extension SpeechAnalysisService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            errorMessage = "Speech recognition became unavailable"
        }
    }
}
