//
//  OpenAudioSDK.swift
//  OpenAudioSDK
//
//  Created by Elijah Arbee on 10/23/24.
//

import Foundation
import Combine
import AVFoundation

/// The primary interface for interacting with the OpenAudioSDK.
/// Manages audio recording, playback, device management, speech recognition, and more.
public class OpenAudioSDK {
    
    // MARK: - Singleton Instance
    
    /// Shared instance of OpenAudioSDK for global access.
    public static let shared = OpenAudioSDK()
    
    // MARK: - Private Properties
    
    private let audioEngineManager: AudioEngineManagerProtocol
    private let audioState: AudioStateProtocol
    private let audioFileManager: AudioFileManager
    private let deviceManager: DeviceManager
    private let soundMeasurementManager: SoundMeasurementManager
    private let speechRecognitionManager: SpeechRecognitionManager
    private let webSocketManager: WebSocketManagerProtocol
    private let audioConverter: AudioConverter
    private let locationManager: LocationManager
    private let audioPlaybackManager: AudioPlaybackManager
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Publishers
    
    /// Publisher that emits the current audio level in decibels.
    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioEngineManager.audioLevelPublisher
    }
    
    /// Publisher that emits audio buffers for processing.
    public var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> {
        audioEngineManager.audioBufferPublisher
    }
    
    /// Publisher that emits location updates.
    public var locationPublisher: AnyPublisher<LocationData?, Never> {
        locationManager.locationPublisher
    }
    
    /// Publisher that emits transcription text from speech recognition.
    public var transcriptionPublisher: AnyPublisher<String, Never> {
        speechRecognitionManager.$transcribedText.eraseToAnyPublisher()
    }
    
    /// Publisher that emits speech detection status.
    public var speechDetectionPublisher: AnyPublisher<Bool, Never> {
        speechRecognitionManager.$isSpeechDetected.eraseToAnyPublisher()
    }
    
    /// Publisher that emits errors encountered within the SDK.
    public var errorPublisher: AnyPublisher<String?, Never> {
        Publishers.MergeMany(
            audioState.$errorMessage,
            audioPlaybackManager.$errorMessage,
            webSocketManager.receivedDataPublisher.map { _ in nil } // Placeholder for WebSocket errors
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Initializer
    
    /// Private initializer to enforce singleton usage.
    private init() {
        self.audioEngineManager = AudioEngineManager.shared
        self.audioState = AudioState.shared
        self.audioFileManager = AudioFileManager.shared
        self.deviceManager = DeviceManager.shared
        self.soundMeasurementManager = SoundMeasurementManager.shared
        self.speechRecognitionManager = SpeechRecognitionManager.shared
        self.webSocketManager = WebSocketManager(url: URL(string: "wss://yourserver.com/socket")!) // Replace with actual URL
        self.audioConverter = AudioConverter.shared
        self.locationManager = LocationManager.shared
        self.audioPlaybackManager = AudioPlaybackManager.shared
        
        setupBindings()
        configureSpeechRecognition()
    }
    
    // MARK: - Public Methods
    
    /// Starts audio recording with optional live streaming.
    /// - Parameter stream: Indicates whether to stream audio data via WebSocket.
    public func startRecording(stream: Bool = false) {
        if stream {
            audioState.setupWebSocket(manager: webSocketManager)
        }
        audioState.toggleRecording(manual: true)
        speechRecognitionManager.startRecording()
    }
    
    /// Stops the current audio recording.
    public func stopRecording() {
        audioState.stopRecording()
        speechRecognitionManager.stopRecording()
    }
    
    /// Starts audio playback for a given recording URL.
    /// - Parameter url: The URL of the audio recording to play.
    public func playAudio(from url: URL) {
        audioPlaybackManager.startPlayback(for: url)
    }
    
    /// Pauses the current audio playback.
    public func pauseAudioPlayback() {
        audioPlaybackManager.pausePlayback()
    }
    
    /// Deletes a specific audio recording.
    /// - Parameter recording: The `AudioRecording` instance to delete.
    /// - Throws: An error if the deletion fails.
    public func deleteRecording(_ recording: AudioRecording) throws {
        try audioFileManager.deleteRecording(recording)
        audioState.updateLocalRecordings()
    }
    
    /// Converts an audio file from one format to another.
    /// - Parameters:
    ///   - sourceURL: The source audio file URL.
    ///   - destinationURL: The destination audio file URL.
    ///   - outputFormat: The desired output audio format.
    /// - Throws: An `AudioConverterError` if the conversion fails.
    public func convertAudio(from sourceURL: URL, to destinationURL: URL, format outputFormat: AVFileType) async throws {
        try await audioConverter.convertAudio(sourceURL: sourceURL, destinationURL: destinationURL, outputFileType: outputFormat)
    }
    
    /// Requests necessary permissions for audio recording and speech recognition.
    public func requestPermissions() {
        speechRecognitionManager.requestSpeechAuthorization()
        // Add additional permission requests if necessary
    }
    
    /// Fetches the list of local audio recordings.
    /// - Returns: An array of `AudioRecording` instances.
    public func fetchRecordings() -> [AudioRecording] {
        audioState.fetchRecordings()
    }
    
    /// Adds a new audio device to the device manager and connects it.
    /// - Parameter device: The `Device` instance to add.
    public func addAudioDevice(_ device: Device) {
        deviceManager.addDevice(device)
    }
    
    /// Removes an existing audio device from the device manager and disconnects it.
    /// - Parameter device: The `Device` instance to remove.
    public func removeAudioDevice(_ device: Device) {
        deviceManager.removeDevice(device)
    }
    
    /// Starts monitoring audio levels and speech detection.
    public func startMonitoring() {
        soundMeasurementManager.handleAudioLevel = { level in
            // Handle audio level updates if needed
        }
    }
    
    /// Stops monitoring audio levels and speech detection.
    public func stopMonitoring() {
        // Implement if necessary
    }
    
    // MARK: - Private Methods
    
    /// Sets up bindings between various components for cohesive functionality.
    private func setupBindings() {
        // Example: Update audio state based on device connections
        deviceManager.$connectedDevices
            .sink { [weak self] devices in
                // Handle connected devices
                // Example: Start recording on all connected devices
                self?.audioState.startRecordingOnAllDevices()
            }
            .store(in: &cancellables)
        
        // Subscribe to error messages and propagate them through the SDK's errorPublisher
        audioState.$errorMessage
            .sink { [weak self] error in
                if let error = error {
                    // Handle or log the error as needed
                }
            }
            .store(in: &cancellables)
    }
    
    /// Configures speech recognition settings and callbacks.
    private func configureSpeechRecognition() {
        speechRecognitionManager.onSpeechStart = { [weak self] in
            self?.audioState.startRecording(manual: false)
        }
        
        speechRecognitionManager.onSpeechEnd = { [weak self] in
            self?.audioState.stopRecording()
        }
    }
}
