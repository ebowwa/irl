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

// Ensure that the service is only available on iOS 17.0 or later versions
@available(iOS 17.0, *)
class SpeechAnalysisService: NSObject, ObservableObject, SFSpeechRecognitionTaskDelegate {

    // Singleton instance to make this service globally accessible
    static let shared = SpeechAnalysisService()

    // Published variables to notify the UI of changes in speech analysis state
    @Published var analysisProbabilities: [URL: Double] = [:]  // Mapping of recording URLs to their analysis probabilities
    @Published var isAnalyzing: Bool = false  // Indicates if a recording is currently being analyzed
    @Published var errorMessage: String?  // Stores any error messages to display to the user
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined  // Stores the current speech recognition authorization status

    private var speechRecognizer: SFSpeechRecognizer?  // Optional speech recognizer instance
    private var recognitionTask: SFSpeechRecognitionTask?  // Optional task for ongoing recognition
    private var currentRecordingURL: URL?  // Stores the URL of the current recording being analyzed
    private let analysisQueue = DispatchQueue(label: "com.yourapp.speechAnalysis", qos: .userInitiated)  // Queue for background processing

    // Initializer to set up the speech recognizer and permissions
    private override init() {
        super.init()
        setupSpeechRecognizer()  // Configure the speech recognizer
    }

    // Initializes the speech recognizer and checks for user permissions
    private func setupSpeechRecognizer() {
        self.speechRecognizer = SFSpeechRecognizer()  // Create a new speech recognizer instance
        self.speechRecognizer?.delegate = self  // Assign the delegate for handling recognizer events
        checkSpeechRecognitionPermission()  // Check or request permissions for speech recognition
    }

    // Method to print locale information for debugging purposes
    private func setupLanguageModel() {
        if let locale = speechRecognizer?.locale {
            print("Speech recognizer initialized with locale: \(locale.identifier)")  // Prints the locale of the speech recognizer
        } else {
            print("Speech recognizer locale not available")  // Warns if locale info is not available
        }
    }

    // Allows changing the recognizer's language by initializing a new speech recognizer with the desired locale
    func changeLanguage(to identifier: String) {
        guard let newRecognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier)) else {
            print("Failed to create speech recognizer for locale: \(identifier)")  // Handles failure in creating a new recognizer for the locale
            return
        }
        
        // Dispatches changes to the main thread as UI updates should not be done in the background thread
        DispatchQueue.main.async {
            self.speechRecognizer?.delegate = nil  // Remove the old delegate
            self.speechRecognizer = newRecognizer  // Replace the old recognizer with the new one
            self.speechRecognizer?.delegate = self  // Assign the delegate to the new recognizer
            print("Changed speech recognizer to locale: \(identifier)")  // Logs the locale change
            self.setupLanguageModel()  // Reinitialize the language model for the new locale
        }
    }

    // Checks and requests the user's permission to use speech recognition services
    func checkSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.authorizationStatus = status  // Update the authorization status for UI binding
                switch status {
                case .authorized:
                    print("Speech recognition authorized")  // Speech recognition permission granted
                    self.setupLanguageModel()  // Configure language model after authorization
                case .denied:
                    self.errorMessage = "Speech recognition permission denied"  // Permission denied
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted on this device"  // Speech recognition restricted
                case .notDetermined:
                    self.errorMessage = "Speech recognition permission not determined"  // Speech recognition permission not set yet
                @unknown default:
                    self.errorMessage = "Unknown speech recognition authorization status"  // Catch-all for any unexpected statuses
                }
            }
        }
    }

    // Analyzes a single audio recording, ensuring that recognition is authorized before starting
    func analyzeRecording(_ recording: AudioRecording) async {
        // Ensure the app has permission to use speech recognition
        guard authorizationStatus == .authorized else {
            await MainActor.run {
                errorMessage = "Speech recognition is not authorized"
                isAnalyzing = false
            }
            return
        }

        // Mark the analysis as started and clear any previous errors
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
            currentRecordingURL = recording.url  // Store the current audio URL being analyzed
        }

        // Ensure that the speech recognizer is available before proceeding
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            await MainActor.run {
                errorMessage = "Speech recognition is not available"  // Notify if speech recognition is unavailable
                isAnalyzing = false
            }
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: recording.url)  // Create a recognition request using the recording's URL

        // Perform the recognition asynchronously and handle errors
        do {
            let result: SFSpeechRecognitionResult = try await withCheckedThrowingContinuation { continuation in
                recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                    if let error = error {
                        continuation.resume(throwing: error)  // If an error occurs, pass it to the continuation
                    } else if let result = result, result.isFinal {
                        continuation.resume(returning: result)  // If the result is final, return it
                    }
                }
            }
            await processResult(result)  // Process the speech recognition result
        } catch {
            await MainActor.run {
                errorMessage = "Speech recognition failed: \(error.localizedDescription)"  // Handle speech recognition failure
                isAnalyzing = false  // Reset analyzing state
            }
        }
    }

    // Loops through multiple audio recordings and analyzes each one sequentially
    func analyzeAllRecordings(_ recordings: [AudioRecording]) async {
        for recording in recordings {
            await analyzeRecording(recording)  // Analyze each recording one by one
        }
    }

    // Processes the result from the speech recognizer, calculates word count and speech probability
    private func processResult(_ result: SFSpeechRecognitionResult) async {
        let wordCount = result.bestTranscription.segments.reduce(into: 0) { $0 += $1.substring.split(separator: " ").count }  // Count words in the transcription
        let durationInSeconds = result.bestTranscription.segments.last?.duration ?? 0  // Get the duration of the last segment

        // Assume an average speaking rate of 2 words per second to estimate expected word count
        let expectedWordCount = durationInSeconds * 2

        // Calculate the percentage of expected word count, capping at 100%
        let percentage = min((Double(wordCount) / expectedWordCount) * 100, 100)

        // Update the analysis probability for the current recording and stop analyzing
        await MainActor.run {
            guard let currentURL = self.currentRecordingURL else { return }  // Ensure there's a valid URL
            self.analysisProbabilities[currentURL] = percentage  // Store the calculated percentage for the current recording
            self.isAnalyzing = false  // Mark analysis as complete
        }
    }

    // Cancels any ongoing speech recognition tasks
    func cancelOngoingTasks() {
        recognitionTask?.cancel()  // Cancel the current recognition task, if any
        recognitionTask = nil  // Reset the task to nil
        isAnalyzing = false  // Reset analyzing state
    }
}

// Conform to SFSpeechRecognizerDelegate to handle changes in availability
extension SpeechAnalysisService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            errorMessage = "Speech recognition became unavailable"  // Notify when speech recognition becomes unavailable
        }
    }
}
