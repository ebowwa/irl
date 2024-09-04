//
//  SpeechAnalysisService.swift
//  This service handles speech analysis, including detecting if audio files are worth sending for transcription and prosody analysis.
//  It also manages a queue of audio files ready for analysis and provides an on/off widget for user control.
//
//  Created by Elijah Arbee on 8/30/24.
// TODO: correct analysis result, currently will determine, but often will need a full page refresh to change state and if no speech is deteched it will still say analyzing not no speech detected
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

    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var customLanguageModel: SFCustomLanguageModelData?
    private var currentRecordingURL: URL?
    private let analysisQueue = DispatchQueue(label: "com.yourapp.speechAnalysis", qos: .userInitiated)

    private override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        self.speechRecognizer?.delegate = self
        setupCustomLanguageModel()
    }

    // Setup custom language model for enhanced speech recognition
    private func setupCustomLanguageModel() {
        customLanguageModel = SFCustomLanguageModelData(
            locale: Locale(identifier: "en-US"),
            identifier: "com.yourapp.speechmodel",
            version: "1.0"
        )

        let generator = SFCustomLanguageModelData.TemplatePhraseCountGenerator()
        generator.define(className: "greeting", values: ["hello", "hi", "hey", "good morning", "good afternoon", "good evening"])
        generator.define(className: "name", values: ["Alice", "Bob", "Charlie", "David", "Emma", "Frank", "Grace", "Henry"])

        generator.insert(template: "<greeting> <name>", count: 100)
        generator.insert(template: "How are you, <name>?", count: 50)
        generator.insert(template: "It's nice to meet you, <name>", count: 50)

        customLanguageModel?.insert(phraseCountGenerator: generator)
    }

    // Analyze a single audio recording

    func analyzeRecording(_ recording: AudioRecording) async {
        isAnalyzing = true
        errorMessage = nil
        currentRecordingURL = recording.url

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available"
            isAnalyzing = false
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: recording.url)
        // Attempt to use custom language model, though not directly supported by SFSpeechURLRecognitionRequest
        if let customLanguageModel = customLanguageModel {
            do {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("customModel.bin")
                try await customLanguageModel.export(to: tempURL)
            } catch {
                errorMessage = "Failed to create custom language model: \(error.localizedDescription)"
            }
        }

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
            processResult(result)
        } catch {
            errorMessage = "Speech recognition failed: \(error.localizedDescription)"
            isAnalyzing = false
        }
    }

    // Analyze multiple audio recordings
    func analyzeAllRecordings(_ recordings: [AudioRecording]) async {
        for recording in recordings {
            await analyzeRecording(recording)
        }
    }

    // Process the result of a speech recognition task
    private func processResult(_ result: SFSpeechRecognitionResult) {
        let wordCount = result.bestTranscription.segments.reduce(into: 0) { $0 += $1.substring.split(separator: " ").count }
        let durationInSeconds = result.bestTranscription.segments.last?.duration ?? 0

        // Assume an average speaking rate of 2 words per second
        let expectedWordCount = durationInSeconds * 2

        // Calculate percentage, capping at 100%
        let percentage = min((Double(wordCount) / expectedWordCount) * 100, 100)

        DispatchQueue.main.async { [weak self] in
            guard let self = self, let currentURL = self.currentRecordingURL else { return }
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
