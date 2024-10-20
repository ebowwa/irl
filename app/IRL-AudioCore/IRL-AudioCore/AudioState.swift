//
//  AudioState.swift
//  IRL-AudioCore
//
//  Created by Elijah Arbee on 10/20/24.
//


//
//  AudioState.swift
//  AudioFramework
//
//  Created by Elijah Arbee on 8/29/24.
//

import Foundation
import AVFoundation
import Combine
import UIKit // Needed for UIApplication and UIDevice
import Speech // Needed for SFSpeechRecognizer and related classes

// MARK: - AudioState Class

public class AudioState: NSObject, AudioStateProtocol { // Removed AVAudioPlayerDelegate conformance from class
    
    // Singleton instance to ensure one central state for audio management.
    public static let shared = AudioState()

    // MARK: - Published Properties

    @Published public var isRecording = false // Tracks if recording is in progress.
    @Published public var isPlaying = false // Tracks if playback is in progress.
    @Published public var recordingTime: TimeInterval = 0 // The time length of the current recording.
    @Published public var recordingProgress: Double = 0 // Progress of the recording session.
    @Published public var currentRecording: AudioRecording? // The recording currently being played or recorded.
    @Published public var isPlaybackAvailable = false // Indicates if playback can be started for the current recording.
    @Published public var errorMessage: String? // Holds error messages related to recording, playback, or speech recognition.
    @Published public var localRecordings: [AudioRecording] = [] // List of recordings fetched from local storage.

    // Persistent storage for recording-related settings
    private(set) public var isRecordingEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isRecordingEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isRecordingEnabled") }
    }
    private(set) public var isBackgroundRecordingEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "isBackgroundRecordingEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "isBackgroundRecordingEnabled") }
    }

    // AVFoundation components for handling audio recording and playback.
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    private var recordingTimer: Timer? // Timer for tracking recording duration.
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) // For speech recognition tasks.

    // Combine subject to track audio levels in real-time.
    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher() // Allows external subscribers to receive audio level updates.
    }

    private var audioEngine: AVAudioEngine? // For live audio streaming.
    private var webSocketManager: WebSocketManagerProtocol? // WebSocket manager for live audio streaming.
    private let audioBufferSize: AVAudioFrameCount = 1024 // Size of the audio buffer for live streaming.

    private var cancellables: Set<AnyCancellable> = [] // Stores Combine subscriptions.

    // MARK: - Initializer

    // Private initializer to enforce singleton pattern.
    private override init() {
        super.init()
        setupAudioSession(caller: "AudioState.init") // Setup called once during initialization.
        updateLocalRecordings() // Loads any existing recordings from disk.
        setupNotifications() // Setup app lifecycle notifications.

        // Automatically start recording if background recording is enabled
        if isBackgroundRecordingEnabled {
            startRecording()
        }
    }

    // MARK: - Notification Setup

    // Registers for system notifications related to the app's lifecycle.
    private func setupNotifications() {
        // Listen for when the app is about to go into the background (resign active).
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppBackgrounding), name: UIApplication.willResignActiveNotification, object: nil)
        
        // Listen for when the app is about to terminate.
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTermination), name: UIApplication.willTerminateNotification, object: nil)
    }

    // Handles the app going into the background. If background recording is allowed, continue recording; otherwise, stop.
    @objc private func handleAppBackgrounding() {
        // If background recording is allowed, ensure the audio session is set up correctly.
        if isBackgroundRecordingEnabled {
            setupAudioSession()
        } else {
            // Otherwise, stop recording when the app is backgrounded.
            stopRecording()
        }
    }

    // Handles the app termination. Ensures that recording stops to prevent data loss or resource leaks.
    @objc private func handleAppTermination() {
        // If recording is active when the app is terminating, stop the recording process.
        if isRecording {
            stopRecording()
        }
    }

    // MARK: - WebSocket Setup

    // Assigns the WebSocket manager, enabling live audio streaming functionality.
    public func setupWebSocket(manager: WebSocketManagerProtocol) {
        self.webSocketManager = manager
    }

    // MARK: - Audio Session Setup

    /// Configures the AVAudioSession to allow both playback and recording.
    /// - Parameter caller: A string indicating who called this method, for logging purposes.
    private func setupAudioSession(caller: String = #function) {
        // Log device information
        let device = UIDevice.current
        let deviceInfo = "Device: \(device.model), OS: \(device.systemName) \(device.systemVersion)"
        print("[DeviceInfo] Called by \(caller) - \(deviceInfo)")

        recordingSession = AVAudioSession.sharedInstance()

        // Check current session configuration
        let currentCategory = recordingSession?.category ?? .ambient
        let currentMode = recordingSession?.mode ?? .default
        let currentOptions = recordingSession?.categoryOptions ?? []

        if currentCategory == .playAndRecord &&
            currentMode == .default &&
            currentOptions.contains(.defaultToSpeaker) &&
            currentOptions.contains(.allowBluetooth) {
            print("[setupAudioSession] Called by \(caller) - Audio session already configured.")
            return
        }

        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(true)
            print("[setupAudioSession] Called by \(caller) - Audio session successfully set up")
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
                print("[setupAudioSession] Called by \(caller) - Setup failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Recording Controls

    /// Toggles between starting and stopping a recording session.
    public func toggleRecording() {
        if isRecording {
            stopRecording() // If already recording, stop the current session.
        } else {
            startRecording() // Otherwise, begin a new recording session.
        }
    }

    /// Starts either live streaming or file-based recording depending on the presence of a WebSocketManager.
    public func startRecording() {
        if isRecording {
            stopRecording()
        }

        if webSocketManager != nil {
            startLiveStreaming()
        } else {
            startFileRecording()
        }
    }

    /// Stops the current recording, whether live-streaming or file-based, and updates the UI and local recordings.
    public func stopRecording() {
        if let audioEngine = audioEngine {
            audioEngine.stop() // Stop the audio engine if live streaming.
            audioEngine.inputNode.removeTap(onBus: 0)
            self.audioEngine = nil
        } else {
            audioRecorder?.stop() // Otherwise, stop the file-based recording.
        }

        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.stopRecordingTimer() // Stop the timer tracking the recording length.
            self?.updateCurrentRecording() // Save the recorded file and update the list of recordings.
            self?.updateLocalRecordings()
            self?.isPlaybackAvailable = true // After recording is stopped, playback becomes available.
        }
    }

    // MARK: - Live Streaming

    /// Starts live audio streaming using AVAudioEngine.
    private func startLiveStreaming() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to create audio engine"
            }
            return
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Tapping into the audio stream and processing the microphone buffer for live streaming.
        inputNode.installTap(onBus: 0, bufferSize: audioBufferSize, format: inputFormat) { [weak self] (buffer, time) in
            self?.processMicrophoneBuffer(buffer: buffer, time: time)
        }

        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                try audioEngine.start() // Starts the audio engine to begin capturing audio data.
                DispatchQueue.main.async {
                    self?.isRecording = true
                    self?.recordingTime = 0
                    self?.recordingProgress = 0
                    self?.startRecordingTimer() // Starts a timer to track the duration of the recording.
                    self?.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Processes the captured audio buffer and sends it via WebSocket for live streaming.
    private func processMicrophoneBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let channelData = buffer.floatChannelData else { return }
        let frames = buffer.frameLength

        var data = Data(capacity: Int(frames) * MemoryLayout<Float>.size)
        for i in 0..<Int(frames) {
            var sample = channelData[0][i] // Changed from 'let' to 'var'
            data.append(Data(bytes: &sample, count: MemoryLayout<Float>.size))
        }

        webSocketManager?.sendAudioData(data) // Sends the processed audio data to the WebSocket server.
    }

    // MARK: - File Recording

    /// Starts a new file-based recording, saving the audio data locally.
    private func startFileRecording() {
        // Generates a unique file path for the recording based on the current timestamp.
        let audioFilename = AudioFileManager.shared.getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")

        // Audio settings for the recording session (AAC format, high-quality audio).
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Attempts to start the recording with the specified settings.
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self // Set the delegate to respond to recording events
            audioRecorder?.record()

            DispatchQueue.main.async { [weak self] in
                self?.isRecording = true
                self?.recordingTime = 0
                self?.recordingProgress = 0
                self?.startRecordingTimer() // Starts a timer to track recording duration.
                self?.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Could not start recording: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Recording Timer

    /// Starts a timer that increments the recording duration every 0.1 seconds and updates the audio levels.
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.recordingTime += 0.1
                self.updateAudioLevels() // Updates the current audio levels during the recording.
            }
        }
    }

    /// Stops the timer that tracks the recording duration.
    private func stopRecordingTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.recordingTimer?.invalidate()
            self?.recordingTimer = nil
        }
    }

    /// Updates the audio levels by querying the current recording's meter data.
    private func updateAudioLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters() // Updates the metering information for the audio input.
        let averagePower = recorder.averagePower(forChannel: 0)
        DispatchQueue.main.async { [weak self] in
            self?.audioLevelSubject.send(averagePower) // Publishes on the main thread.
        }
    }

    // MARK: - File Management

    /// Saves the current recording and updates the list of local recordings.
    private func updateCurrentRecording() {
        guard let url = audioRecorder?.url else { return }
        let fileManager = AudioFileManager.shared
        let recordings = fileManager.updateLocalRecordings() // Fetches the latest recordings from local storage.
        currentRecording = recordings.first { $0.url == url } // Sets the current recording based on the URL.

        // Performs speech likelihood analysis on the newly saved recording.
        if let recording = currentRecording {
            determineSpeechLikelihood(for: recording.url) { [weak self] isSpeechLikely in
                DispatchQueue.main.async {
                    self?.currentRecording?.isSpeechLikely = isSpeechLikely
                    self?.updateLocalRecordings() // Updates local recordings with speech likelihood info.
                }
            }
        }
    }

    /// Updates the list of local recordings by querying the file system for saved recordings.
    public func updateLocalRecordings() {
        let updatedRecordings = AudioFileManager.shared.updateLocalRecordings()

        // For each recording, if speech likelihood has not been determined, initiate speech analysis.
        for recording in updatedRecordings {
            if recording.isSpeechLikely == nil {
                determineSpeechLikelihood(for: recording.url) { [weak self] isSpeechLikely in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let index = self.localRecordings.firstIndex(where: { $0.url == recording.url }) {
                            self.localRecordings[index].isSpeechLikely = isSpeechLikely // Updates likelihood result.
                        }
                    }
                }
            }
        }

        DispatchQueue.main.async { [weak self] in
            self?.localRecordings = updatedRecordings // Updates the local recordings array to reflect changes.
        }
    }

    /// Fetches the list of recordings, useful for reloading the list in the UI.
    public func fetchRecordings() {
        updateLocalRecordings()
    }

    /// Deletes a recording file from local storage and updates the list of recordings.
    public func deleteRecording(_ recording: AudioRecording) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                try AudioFileManager.shared.deleteRecording(recording) // Attempts to delete the recording file.
                DispatchQueue.main.async {
                    self?.updateLocalRecordings()

                    // If the deleted recording was the current one, reset playback availability.
                    if self?.currentRecording?.url == recording.url {
                        self?.currentRecording = nil
                        self?.isPlaybackAvailable = false
                    }

                    self?.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Error deleting recording: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Speech Recognition

    /// Determines if the audio file contains speech by running it through the speech recognizer.
    private func determineSpeechLikelihood(for url: URL, completion: @escaping (Bool) -> Void) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        speechRecognizer?.recognitionTask(with: request) { result, error in
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

            // Analyzes the speech transcription result and confidence to determine if speech is present.
            let isSpeechLikely = result.bestTranscription.formattedString.split(separator: " ").count > 1 &&
                                (result.bestTranscription.segments.first?.confidence ?? 0 > 0.5)
            DispatchQueue.main.async {
                completion(isSpeechLikely)
            }
        }
    }

    // MARK: - Playback Controls

    /// Toggles between starting and pausing playback.
    public func togglePlayback() {
        if isPlaying {
            pausePlayback() // If currently playing, pause the playback.
        } else {
            startPlayback() // Otherwise, start playback.
        }
    }

    /// Starts playback of the current recording.
    private func startPlayback() {
        guard let recording = currentRecording else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "No recording available to play"
            }
            return
        }

        // Attempts to play the recording using AVAudioPlayer.
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.url)
            audioPlayer?.delegate = self // Set the delegate to respond to playback events.
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = true
                self?.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Error playing audio: \(error.localizedDescription)"
            }
        }
    }

    /// Pauses playback of the current recording.
    private func pausePlayback() {
        audioPlayer?.pause()
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
        }
    }

    // MARK: - Formatting Helpers

    /// Formats the recording duration for display purposes.
    public var formattedRecordingTime: String {
        AudioFileManager.shared.formattedDuration(recordingTime)
    }

    /// Formats the file size of a recording for display.
    public func formattedFileSize(bytes: Int64) -> String {
        AudioFileManager.shared.formattedFileSize(bytes: bytes)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioState: AVAudioRecorderDelegate {
    // Called when recording finishes, either successfully or with an error.
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Recording failed to finish successfully."
                self?.isRecording = false
            }
        }
    }

    // Called when recording encounters an encoding error.
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Recording encoding error: \(error.localizedDescription)"
                self?.isRecording = false
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioState: AVAudioPlayerDelegate { // Removed redundant conformance
    // Called when playback finishes, either successfully or with an error.
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false // Resets the isPlaying flag when playback is finished.
            if !flag {
                self?.errorMessage = "Playback finished with an error"
            }
        }
    }

    // Called when playback encounters an error.
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Playback decode error: \(error.localizedDescription)"
                self?.isPlaying = false
            }
        }
    }
}
