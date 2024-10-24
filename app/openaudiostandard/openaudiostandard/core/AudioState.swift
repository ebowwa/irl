// AudioState.swift
// openaudiostandard

import Foundation
import AVFoundation
import Combine
import UIKit
import Speech

// MARK: - AudioState Class

public class AudioState: NSObject, AudioStateProtocol {
    
    // Singleton instance to ensure one central state for audio management.
    public static let shared = AudioState()
    
    // MARK: - Published Properties
    
    @Published public var isRecording: Bool = false
    @Published public var isPlaying: Bool = false
    @Published public var recordingTime: TimeInterval = 0
    @Published public var recordingProgress: Double = 0
    @Published public var isPlaybackAvailable: Bool = false
    @Published public var errorMessage: String?
    @Published public var localRecordings: [AudioRecording] = []
    @Published public var currentRecording: AudioRecording?
    
    // MARK: - Persistent Storage Properties
    
    private let userDefaults = UserDefaults.standard
    private let isRecordingEnabledKey = "isRecordingEnabled"
    private let isBackgroundRecordingEnabledKey = "isBackgroundRecordingEnabled"
    
    public var isRecordingEnabled: Bool {
        get { userDefaults.bool(forKey: isRecordingEnabledKey) }
        set { userDefaults.set(newValue, forKey: isRecordingEnabledKey) }
    }
    
    public var isBackgroundRecordingEnabled: Bool {
        get { userDefaults.bool(forKey: isBackgroundRecordingEnabledKey) }
        set { userDefaults.set(newValue, forKey: isBackgroundRecordingEnabledKey) }
    }
    
    // MARK: - AVFoundation Components
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    private var recordingTimer: Timer? // Timer for tracking recording duration.
    
    // MARK: - Managers
    
    private let speechRecognitionManager = SpeechRecognitionManager.shared
    private let soundMeasurementManager = SoundMeasurementManager.shared
    
    // MARK: - WebSocket Manager
    
    private var webSocketManager: WebSocketManagerProtocol? // WebSocket manager for live audio streaming
    
    // MARK: - Recording Control Flags
    
    private var isManualRecording: Bool = false // Indicates if the current recording was started manually.
    
    // MARK: - Publishers
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Audio Level Publisher
    
    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        soundMeasurementManager.$currentAudioLevel
            .map { Float($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Error Message Publisher
    
    public var errorMessagePublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization

    private override init() {
        super.init()
        setupAudioSession(caller: "AudioState.init") // Setup called once during initialization.
        setupNotifications() // Setup app lifecycle notifications.
        setupSpeechRecognitionManager() // Setup speech detection callbacks
        setupBindings() // Setup bindings with SoundMeasurementManager and AudioEngineManager
        updateLocalRecordings() // Loads any existing recordings from disk.
        
        // Automatically start recording if background recording is enabled
        if isBackgroundRecordingEnabled {
            startRecording(manual: false)
        }
    }
    
    // MARK: - Setup Methods
    
    /// Sets up bindings to receive audio levels from SoundMeasurementManager.
    private func setupBindings() {
        // Subscribe to audio level updates from SoundMeasurementManager
        soundMeasurementManager.$currentAudioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.recordingProgress = level
            }
            .store(in: &cancellables)
        
        // Subscribe to speech detection updates if needed
        // Additional bindings can be added here
    }
    
    /// Sets up speech detection callbacks.
    private func setupSpeechRecognitionManager() {
        // Set up speech detection handlers
        speechRecognitionManager.onSpeechStart = { [weak self] in
            guard let self = self else { return }
            if self.isRecordingEnabled && !self.isRecording && !self.isManualRecording {
                self.startRecording(manual: false)
            }
        }
        
        speechRecognitionManager.onSpeechEnd = { [weak self] in
            guard let self = self else { return }
            if self.isRecordingEnabled && self.isRecording && !self.isManualRecording {
                self.stopRecording()
            }
        }
        
        // **Remove subscription to $isAuthorized**
        // The SpeechRecognitionManager now handles authorization internally
        
        // **Remove requestSpeechAuthorization()**
        // Authorization is now managed by SpeechAuthorizationManager and SpeechRecognitionManager
    }
    
    /// Registers for system notifications related to the app's lifecycle.
    private func setupNotifications() {
        // Listen for when the app is about to go into the background (resign active).
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppBackgrounding), name: UIApplication.willResignActiveNotification, object: nil)
        
        // Listen for when the app is about to terminate.
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTermination), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    // MARK: - Notification Handlers
    
    // Handles the app going into the background. If background recording is allowed, continue recording; otherwise, stop.
    @objc private func handleAppBackgrounding() {
        // If background recording is allowed, ensure the audio session is set up correctly.
        if isBackgroundRecordingEnabled {
            setupAudioSession(caller: "handleAppBackgrounding")
            // Start audio engine if needed
            if !AudioEngineManager.shared.isEngineRunning {
                AudioEngineManager.shared.startEngine()
            }
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
    
    /// Assigns the WebSocket manager, enabling live audio streaming functionality.
    public func setupWebSocket(manager: WebSocketManagerProtocol) {
        self.webSocketManager = manager
        AudioEngineManager.shared.assignWebSocketManager(manager: manager) // Assign WebSocket manager to AudioEngineManager
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
            try recordingSession?.setActive(true, options: .notifyOthersOnDeactivation)
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
    /// - Parameter manual: Indicates if the recording is manually initiated by the user.
    public func toggleRecording(manual: Bool) {
        if isRecording {
            stopRecording()
        } else {
            startRecording(manual: manual)
        }
    }
    
    /// Starts either live streaming or file-based recording depending on the presence of a WebSocketManager.
    /// - Parameter manual: Indicates if the recording is manually initiated by the user.
    public func startRecording(manual: Bool) {
        if isRecording {
            return
        }
        
        isManualRecording = manual
        
        if webSocketManager != nil {
            // Start live streaming via AudioEngineManager
            audioEngineManager.startEngine()
            // Start file recording
            startFileRecording()
            DispatchQueue.main.async { [weak self] in
                self?.isRecording = true
                self?.recordingTime = 0
                self?.recordingProgress = 0
                self?.startRecordingTimer() // Starts a timer to track the duration of the recording.
                self?.errorMessage = nil
            }
        } else {
            startFileRecording()
        }
    }
    
    /// Stops the current recording, whether live-streaming or file-based, and updates the UI and local recordings.
    public func stopRecording() {
        if !isRecording {
            return
        }
        
        if webSocketManager != nil {
            // Stop live streaming via AudioEngineManager
            audioEngineManager.stopEngine()
        }
        
        // Stop file recording
        audioRecorder?.stop()
        
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.stopRecordingTimer() // Stop the timer tracking the recording length.
            self?.updateCurrentRecording() // Save the recorded file and update the list of recordings.
            self?.updateLocalRecordings()
            self?.isPlaybackAvailable = true // After recording is stopped, playback becomes available.
            self?.isManualRecording = false
        }
    }
    
    // MARK: - File Recording
    
    /// Starts a new file-based recording, saving the audio data locally.
    private func startFileRecording() {
        let audioFilename = AudioFileManager.shared.getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        
        // Updated Audio Settings for Linear PCM
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000, // 16 kHz is recommended for speech recognition
            AVNumberOfChannelsKey: 1, // Mono channel is sufficient for speech
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            DispatchQueue.main.async { [weak self] in
                self?.isRecording = true
                self?.recordingTime = 0
                self?.recordingProgress = 0
                self?.startRecordingTimer()
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
            self?.recordingProgress = self?.mapAudioLevelToProgress(averagePower) ?? 0
        }
    }
    
    /// Maps average power to a progress value (0.0 to 1.0)
    /// - Parameter averagePower: The average power in decibels.
    /// - Returns: A normalized progress value.
    private func mapAudioLevelToProgress(_ averagePower: Float) -> Double {
        // Example mapping from decibels (-160 dB to 0 dB) to progress (0.0 to 1.0)
        let minDb: Float = -160
        let maxDb: Float = 0
        let normalized = (averagePower - minDb) / (maxDb - minDb)
        return Double(max(0, min(1, normalized)))
    }
    
    // MARK: - File Management
    
    /// Saves the current recording and updates the list of local recordings.
    private func updateCurrentRecording() {
        guard let url = audioRecorder?.url else { return }
        let fileManager = AudioFileManager.shared
        let recordings = fileManager.updateLocalRecordings()
        currentRecording = recordings.first { $0.url == url }
        
        // Perform speech likelihood analysis using SpeechRecognitionManager
        if let recording = currentRecording {
            speechRecognitionManager.determineSpeechLikelihood(for: recording.url) { [weak self] isSpeechLikely in
                DispatchQueue.main.async {
                    self?.currentRecording?.isSpeechLikely = isSpeechLikely
                    self?.updateLocalRecordings()
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
                speechRecognitionManager.determineSpeechLikelihood(for: recording.url) { [weak self] isSpeechLikely in
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
    public func fetchRecordings() -> [AudioRecording] {
        updateLocalRecordings()
        return localRecordings
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
    
    // MARK: - Audio Level Handling
    
    /// Handles incoming audio level updates from SoundMeasurementManager.
    /// - Parameter level: The current audio level as a normalized Double.
    // Already handled via bindings in setupBindings()
    
    // MARK: - Formatting Helpers
    
    /// Formats the recording duration for display purposes.
    public var formattedRecordingTime: String {
        AudioFileManager.shared.formattedDuration(recordingTime)
    }
    
    /// Formats the file size of a recording for display.
    public func formattedFileSize(bytes: Int64) -> String {
        AudioFileManager.shared.formattedFileSize(bytes: bytes)
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Recording failed to finish successfully."
                self?.isRecording = false
            }
        }
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Recording encoding error: \(error.localizedDescription)"
                self?.isRecording = false
            }
        }
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false // Resets the isPlaying flag when playback is finished.
            if !flag {
                self?.errorMessage = "Playback finished with an error"
            }
        }
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Playback decode error: \(error.localizedDescription)"
                self?.isPlaying = false
            }
        }
    }
}
