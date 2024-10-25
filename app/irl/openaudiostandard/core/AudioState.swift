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
    // Persistent user preferences for background recording and manual recording controls
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
    
    // Manages sound levels for real-time analysis
    private let soundMeasurementManager = SoundMeasurementManager.shared
    // Recording manager following the protocol, facilitating clean substitution if needed
    private let recordingManager: RecordingManagerProtocol
    // Handles audio playback
    private let playbackManager: AudioPlaybackManager = AudioPlaybackManager()
    
    // MARK: - WebSocket Manager
    // WebSocket manager for live audio streaming—injectable to allow flexibility in implementation
    private var webSocketManager: WebSocketManagerProtocol?
    
    // MARK: - Recording Control Flags
    // Flag to differentiate manual and automatic recording starts
    private var isManualRecording: Bool = false
    
    // MARK: - Publishers
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Recording Properties
    private var recordingTimer: Timer? // Timer for updating recording progress
    
    // MARK: - Initialization

    public override init() { // Changed to 'public' to align with class access level
        self.recordingManager = RecordingScript() // Default recording manager implementation
        super.init()
        
        // Initial setup tasks
        setupAudioSession(caller: "AudioState.init")
        setupNotifications() // Set up observers for app backgrounding and termination
        setupBindings() // Bind published properties for real-time updates
        updateLocalRecordings() // Load initial recordings
        
        // Automatically start background recording if enabled
        if isBackgroundRecordingEnabled {
            startRecording(manual: false)
        }
    }
    
    // MARK: - Setup Methods
    
    // Sets up the data bindings between managers and state
    private func setupBindings() {
        // Bind SoundMeasurementManager's audio level to recordingProgress
        soundMeasurementManager.$currentAudioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.recordingProgress = level // Update UI with real-time audio level
            }
            .store(in: &cancellables)
        
        // Bind RecordingManager's published properties to AudioState's properties
        recordingManager.isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording // Sync recording state
            }
            .store(in: &cancellables)
        
        recordingManager.recordingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.recordingTime = time // Update recording time for UI display
            }
            .store(in: &cancellables)
        
        recordingManager.recordingProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.recordingProgress = progress // Sync recording progress
            }
            .store(in: &cancellables)
        
        recordingManager.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error // Sync error message for UI alerts
            }
            .store(in: &cancellables)
        
        // Bind PlaybackManager's isPlaying to AudioState's isPlaying
        playbackManager.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPlaying in
                self?.isPlaying = isPlaying // Sync playback state
            }
            .store(in: &cancellables)
        
        // Bind PlaybackManager's errorMessage to AudioState's errorMessage
        playbackManager.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.errorMessage = error // Handle playback errors
                }
            }
            .store(in: &cancellables)
    }
    
    // Sets up notification observers for handling app state transitions (backgrounding, termination)
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppBackgrounding), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTermination), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    // MARK: - Notification Handlers
    // Handles app backgrounding, resumes or stops recording based on settings
    @objc private func handleAppBackgrounding() {
        if isBackgroundRecordingEnabled {
            setupAudioSession(caller: "handleAppBackgrounding") // Ensure session is active
            if !AudioEngineManager.shared.isEngineRunning {
                AudioEngineManager.shared.startEngine() // Restart engine if not running
            }
        } else {
            stopRecording() // Stop recording if background recording isn't enabled
        }
    }
    
    // Handles app termination, ensuring any ongoing recording is properly stopped
    @objc private func handleAppTermination() {
        if isRecording {
            stopRecording() // Stop recording on app exit
        }
    }
    
    // MARK: - WebSocket Setup
    // Allows for injecting a WebSocket manager to handle live audio streaming
    public func setupWebSocket(manager: WebSocketManagerProtocol) {
        self.webSocketManager = manager
        AudioEngineManager.shared.assignWebSocketManager(manager: manager) // Connect WebSocket to engine
    }
    
    // MARK: - Audio Session Setup
    // Sets up the audio session for recording and playback
    private func setupAudioSession(caller: String = #function) {
        let device = UIDevice.current
        let deviceInfo = "Device: \(device.model), OS: \(device.systemName) \(device.systemVersion)"
        print("[DeviceInfo] Called by \(caller) - \(deviceInfo)")
        
        // Uncomment the following if the RecordingManager handles audio session setup
        // recordingManager.setupAudioSession(caller: caller)
    }
    
    // MARK: - Recording Controls
    // Toggles recording state based on whether it's already recording
    public func toggleRecording(manual: Bool) {
        if isRecording {
            stopRecording()
        } else {
            startRecording(manual: manual)
        }
    }
    
    // Starts recording, optionally with a manual control flag
    public func startRecording(manual: Bool) {
        if isRecording { return } // Prevent redundant recording start attempts
        
        isManualRecording = manual
        
        if webSocketManager != nil {
            AudioEngineManager.shared.startEngine() // Start the audio engine for WebSocket
            recordingManager.startRecording() // Begin recording
        } else {
            recordingManager.startRecording()
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = true
            self?.recordingTime = 0
            self?.recordingProgress = 0
            self?.errorMessage = nil
        }
    }
    
    // Stops recording and updates relevant states
    public func stopRecording() {
        if !isRecording { return } // Prevent redundant stop attempts
        
        if webSocketManager != nil {
            AudioEngineManager.shared.stopEngine() // Stop the audio engine if WebSocket was active
        }
        
        recordingManager.stopRecording() // Stop the recording manager
        
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.updateCurrentRecording() // Update the list of local recordings
            self?.updateLocalRecordings()
            self?.isPlaybackAvailable = true
            self?.isManualRecording = false
        }
    }
    
    // MARK: - Playback Controls
    // Toggles playback or pauses it based on the current state
    public func togglePlayback() {
        if isPlaying {
            playbackManager.pausePlayback()
        } else if let recordingURL = currentRecording?.url {
            playbackManager.startPlayback(for: recordingURL) // Start playback if a recording is available
        } else {
            errorMessage = "No recording available to play." // Error if no recording is present
        }
    }
    
    // MARK: - File Management
    // Updates the current recording by checking for the latest recorded file
    private func updateCurrentRecording() {
        guard let url = recordingManager.currentRecordingURL() else { return }
        let recordings = AudioFileManager.shared.updateLocalRecordings()
        currentRecording = recordings.first { $0.url == url } // Set current recording based on file URL
    }
    
    // Refreshes the list of local recordings
    public func updateLocalRecordings() {
        let updatedRecordings = AudioFileManager.shared.updateLocalRecordings()
        
        DispatchQueue.main.async { [weak self] in
            self?.localRecordings = updatedRecordings
        }
    }
    
    // Retrieves recordings from local storage
    public func fetchRecordings() {
        updateLocalRecordings()
    }
    
    // Deletes a specific recording and updates the list
    public func deleteRecording(_ recording: AudioRecording) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                try AudioFileManager.shared.deleteRecording(recording) // Attempt to delete the file
                DispatchQueue.main.async {
                    self?.updateLocalRecordings() // Update recordings list after deletion
                    if self?.currentRecording?.url == recording.url {
                        self?.currentRecording = nil // Clear current recording if it was deleted
                        self?.isPlaybackAvailable = false
                    }
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Error deleting recording: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Formatting Helpers
    // Formats recording time into a user-friendly string
    public var formattedRecordingTime: String {
        AudioFileManager.shared.formattedDuration(recordingTime)
    }
    
    // Formats file size into human-readable form
    public func formattedFileSize(bytes: Int64) -> String {
        AudioFileManager.shared.formattedFileSize(bytes: bytes)
    }
    
    // MARK: - AudioLevelPublisher
    // Publishes the current audio level for UI or other purposes
    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        soundMeasurementManager.$currentAudioLevel
            .map { Float($0) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Utility
    // Retrieves the URL of the current recording, if available
    public func currentRecordingURL() -> URL? {
        return recordingManager.currentRecordingURL()
    }
}


// MARK: - AVAudioRecorderDelegate

// Handles AVAudioRecorder events such as recording completion or errors
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
