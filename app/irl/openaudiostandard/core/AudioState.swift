//
//  AudioState.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/23/24.
//

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
    
    // MARK: - Managers
    
    private let speechRecognitionManager = SpeechRecognitionManager.shared
    private let soundMeasurementManager = SoundMeasurementManager.shared
    private let recordingManager: RecordingManagerProtocol
    
    // MARK: - WebSocket Manager
    
    private var webSocketManager: WebSocketManagerProtocol? // WebSocket manager for live audio streaming
    
    // MARK: - Recording Control Flags
    
    private var isManualRecording: Bool = false // Indicates if the current recording was started manually.
    
    // MARK: - Publishers
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Recording Properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    
    // MARK: - Debounce and Stability Tracking
    private var stableBufferCount = 0
    private let stableBufferThreshold = 5 // Number of consecutive stable buffers required
    private let minimumSpeechThreshold: Double = 0.3 // Threshold to consider as speech
    private var speechStartDebounceTimer: Timer?
    private let speechStartDebounceInterval: TimeInterval = 0.5 // 0.5 seconds debounce
    
    // MARK: - Initialization

    private override init() {
        // Initialize RecordingScript and assign to recordingManager
        self.recordingManager = RecordingScript()
        
        super.init()
        
        setupAudioSession(caller: "AudioState.init") // Setup called once during initialization.
        setupNotifications() // Setup app lifecycle notifications.
        setupSpeechRecognitionManager() // Setup speech detection callbacks
        setupBindings() // Setup bindings with SoundMeasurementManager and RecordingManager
        updateLocalRecordings() // Loads any existing recordings from disk.
        
        // Automatically start recording if background recording is enabled
        if isBackgroundRecordingEnabled {
            startRecording(manual: false)
        }
    }
    
    // MARK: - Setup Methods
    
    /// Sets up bindings to receive audio levels from SoundMeasurementManager and RecordingManager.
    private func setupBindings() {
        // Subscribe to audio level updates from SoundMeasurementManager
        soundMeasurementManager.$currentAudioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.recordingProgress = level
            }
            .store(in: &cancellables)
        
        // Subscribe to RecordingManager's published properties
        recordingManager.isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)
        
        recordingManager.recordingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.recordingTime = time
            }
            .store(in: &cancellables)
        
        recordingManager.recordingProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.recordingProgress = progress
            }
            .store(in: &cancellables)
        
        recordingManager.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
        
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
        
        // Delegate audio session setup to RecordingManager
        // Assuming RecordingManager has a method to set up the audio session
        // If not, you can retain the setup logic here
        // recordingManager.setupAudioSession(caller: caller) // Uncomment if implemented
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
            AudioEngineManager.shared.startEngine()
            // Start file recording
            recordingManager.startRecording()
            DispatchQueue.main.async { [weak self] in
                self?.isRecording = true
                self?.recordingTime = 0
                self?.recordingProgress = 0
                self?.errorMessage = nil
            }
        } else {
            recordingManager.startRecording()
        }
    }
    
    /// Stops the current recording, whether live-streaming or file-based, and updates the UI and local recordings.
    public func stopRecording() {
        if !isRecording {
            return
        }
        
        if webSocketManager != nil {
            // Stop live streaming via AudioEngineManager
            AudioEngineManager.shared.stopEngine()
        }
        
        // Stop file recording
        recordingManager.stopRecording()
        
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.updateCurrentRecording() // Save the recorded file and update the list of recordings.
            self?.updateLocalRecordings()
            self?.isPlaybackAvailable = true // After recording is stopped, playback becomes available.
            self?.isManualRecording = false
        }
    }
    
    // MARK: - File Management
    
    /// Saves the current recording and updates the list of local recordings.
    private func updateCurrentRecording() {
        guard let url = recordingManager.currentRecordingURL() else { return }
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
            let audioPlayer = try AVAudioPlayer(contentsOf: recording.url)
            audioPlayer.delegate = self // Set the delegate to respond to playback events.
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            self.audioPlayer = audioPlayer
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
    
    // MARK: - AudioLevelPublisher
    
    /// Publisher that emits the current audio level (normalized between 0.0 and 1.0).
    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        soundMeasurementManager.$currentAudioLevel
            .map { Float($0) }
            .eraseToAnyPublisher()
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
    
    // MARK: - AVAudioPlayerDelegate
    
    private var audioPlayer: AVAudioPlayer?
}

extension AudioState: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Recording did not finish successfully."
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
}

extension AudioState: AVAudioPlayerDelegate {
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

// MARK: - Extension to Expose Recording URL
extension AudioState {
    public func currentRecordingURL() -> URL? {
        return recordingManager.currentRecordingURL()
    }
}
