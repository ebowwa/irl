//
//  SpeechRecognitionConstants.swift
//  IRL-AudioCore
//
//  Created by Elijah Arbee on 10/20/24.
//


//
//  SpeechRecognitionManager.swift
//  AudioFramework
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
    static let bufferSize: AVAudioFrameCount = 1024
    static let backgroundNoiseCollectionDuration: TimeInterval = 10.0
    static let emaAlpha: Double = 0.1
    static let noiseChangeThreshold: Double = 0.05
    static let calibrationCooldown: TimeInterval = 60.0
}

// MARK: - SpeechRecognitionManager

public class SpeechRecognitionManager: ObservableObject {
    public static let shared = SpeechRecognitionManager()

    // MARK: - Published Properties
    @Published public var transcribedText = "Transcribed text will appear here."
    @Published public var transcriptionSegments: [String] = [] // Holds recent segments in a streaming-like fashion
    @Published public var currentAudioLevel: Double = 0.0
    @Published public var averageBackgroundNoise: Double = 0.0
    @Published public var isBackgroundNoiseReady: Bool = false
    @Published public var isSpeechDetected: Bool = false // Flag for detecting if speech is detected
    @Published public var speechMetadata: [String: Any] = [:] // Dictionary to store additional metadata about speech

    // MARK: - Persistent Storage Properties
    private let userDefaults = UserDefaults.standard
    private let isBackgroundNoiseCalibratedKey = "isBackgroundNoiseCalibrated"
    private let averageBackgroundNoisePersistedKey = "averageBackgroundNoisePersisted"

    public var isBackgroundNoiseCalibrated: Bool {
        get { userDefaults.bool(forKey: isBackgroundNoiseCalibratedKey) }
        set { userDefaults.set(newValue, forKey: isBackgroundNoiseCalibratedKey) }
    }

    public var averageBackgroundNoisePersisted: Double {
        get { userDefaults.double(forKey: averageBackgroundNoisePersistedKey) }
        set { userDefaults.set(newValue, forKey: averageBackgroundNoisePersistedKey) }
    }

    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: SpeechRecognitionConstants.locale)!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var backgroundNoiseLevels: [Double] = []
    private var isCollectingBackgroundNoise = false
    private var backgroundNoiseTimer: Timer?
    private var lastTranscription: String = ""
    private var lastCalibrationTime: Date = .distantPast
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Streamed Properties
    private let maxSegmentCount = 10 // Limit how many segments to hold in memory at once for better memory usage

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
            break
        case .denied, .restricted, .notDetermined:
            transcribedText = "Speech recognition not authorized."
        @unknown default:
            transcribedText = "Unknown authorization status."
        }
    }

    // MARK: - Recording Control

    /// Starts the speech recognition recording.
    public func startRecording() {
        guard !audioEngine.isRunning else { return }
        resetRecognitionTask()
        setupAudioSession()
        initializeRecognitionRequest()
        startAudioEngine()
        subscribeToAudioLevelUpdates()
    }

    /// Stops the speech recognition recording.
    public func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
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

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            transcribedText = "Failed to set up audio session: \(error.localizedDescription)"
        }
    }

    // MARK: - Recognition Request Initialization

    private func initializeRecognitionRequest() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            self?.handleStreamingResult(result, error)
        }
    }

    // MARK: - Streaming Transcription Handling

    private func handleStreamingResult(_ result: SFSpeechRecognitionResult?, _ error: Error?) {
        guard let result = result else { return }
        DispatchQueue.main.async {
            // Streaming transcription: handle partial results in real-time
            self.transcribedText = result.bestTranscription.formattedString
            self.updateTranscriptionSegments(from: result.bestTranscription)
            self.isSpeechDetected = !result.bestTranscription.formattedString.isEmpty // Update the speech detection flag
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

    // MARK: - Audio Engine Control

    private func startAudioEngine() {
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: SpeechRecognitionConstants.bufferSize, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.transcribedText = "Listening..."
            }
        } catch {
            transcribedText = "Audio Engine couldn't start: \(error.localizedDescription)"
        }
    }

    // MARK: - Transcription Segments Streaming Update

    private func updateTranscriptionSegments(from transcription: SFTranscription) {
        let newSegments = transcription.segments.dropFirst(transcriptionSegments.count)
        newSegments.forEach { segment in
            let start = transcription.formattedString.index(transcription.formattedString.startIndex, offsetBy: segment.substringRange.location)
            let end = transcription.formattedString.index(start, offsetBy: segment.substringRange.length)
            let substring = String(transcription.formattedString[start..<end])
            
            // Append to segments but ensure we are not holding too many in memory
            transcriptionSegments.append(substring)
            if transcriptionSegments.count > maxSegmentCount {
                transcriptionSegments.removeFirst() // Remove old segments to free up memory
            }
        }
    }

    // MARK: - Audio Level Subscriptions

    private func subscribeToAudioLevelUpdates() {
        AudioState.shared.audioLevelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.handleAudioLevel(level)
            }
            .store(in: &cancellables)
    }

    // MARK: - Background Noise Handling

    private func handleAudioLevel(_ level: Float) {
        let normalizedLevel = AudioUtils.normalizeAudioLevel(level)
        
        if isUserSpeaking() {
            resetBackgroundNoiseCollection()
        } else {
            backgroundNoiseLevels.append(normalizedLevel)
            if !isBackgroundNoiseCalibrated {
                startBackgroundNoiseCollection()
            } else {
                updateNoiseIfCalibrated(normalizedLevel)
            }
        }
        
        adjustCurrentAudioLevelIfReady(normalizedLevel)
    }

    private func isUserSpeaking() -> Bool {
        if transcribedText != lastTranscription && !transcribedText.isEmpty {
            lastTranscription = transcribedText
            return true
        }
        return false
    }

    private func startBackgroundNoiseCollection() {
        guard !isCollectingBackgroundNoise else { return }
        isCollectingBackgroundNoise = true
        backgroundNoiseLevels.removeAll()
        
        backgroundNoiseTimer = Timer.scheduledTimer(withTimeInterval: SpeechRecognitionConstants.backgroundNoiseCollectionDuration, repeats: false) { [weak self] _ in
            self?.computeAverageBackgroundNoise()
            self?.isCollectingBackgroundNoise = false
        }
    }

    private func resetBackgroundNoiseCollection() {
        backgroundNoiseTimer?.invalidate()
        backgroundNoiseTimer = nil
        isCollectingBackgroundNoise = false
        backgroundNoiseLevels.removeAll()
        
        if Date().timeIntervalSince(lastCalibrationTime) > SpeechRecognitionConstants.calibrationCooldown {
            averageBackgroundNoise = 0.0
            isBackgroundNoiseCalibrated = false
            isBackgroundNoiseReady = false
        }
    }
    
    private func computeAverageBackgroundNoise() {
        guard !backgroundNoiseLevels.isEmpty else { return }
        let average = backgroundNoiseLevels.reduce(0, +) / Double(backgroundNoiseLevels.count)
        DispatchQueue.main.async {
            self.updateBackgroundNoise(average)
        }
    }

    private func updateBackgroundNoise(_ average: Double) {
        averageBackgroundNoise = average
        averageBackgroundNoisePersisted = average
        isBackgroundNoiseCalibrated = true
        isBackgroundNoiseReady = true
        lastCalibrationTime = Date()
        print("Average Background Noise Updated: \(averageBackgroundNoisePersisted)")
    }

    private func updateNoiseIfCalibrated(_ normalizedLevel: Double) {
        if Date().timeIntervalSince(lastCalibrationTime) > SpeechRecognitionConstants.calibrationCooldown {
            let newEma = (SpeechRecognitionConstants.emaAlpha * averageBackgroundNoisePersisted) + ((1 - SpeechRecognitionConstants.emaAlpha) * normalizedLevel)
            let change = abs(newEma - averageBackgroundNoisePersisted)
            if change > SpeechRecognitionConstants.noiseChangeThreshold {
                updateBackgroundNoise(newEma)
            }
        }
    }

    // Adjust the currentAudioLevel calculation
    private func adjustCurrentAudioLevelIfReady(_ normalizedLevel: Double) {
        let alpha: Double = 0.3 // Tweak this value to control noise influence
        if isBackgroundNoiseReady {
            let adjustedLevel = max(normalizedLevel - alpha * averageBackgroundNoisePersisted, 0.0)
            currentAudioLevel = adjustedLevel / (1.0 - alpha * averageBackgroundNoisePersisted)
        } else {
            currentAudioLevel = normalizedLevel
        }
    }
}
