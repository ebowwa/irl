// AProtocols.swift
// openaudiostandard
//
// Created by Elijah Arbee on 10/23/24.
//

import Foundation
import Combine
import AVFoundation  // Ensure this import is present

// MARK: - WebSocketManagerProtocol


public protocol WebSocketManagerProtocol {
    var isConnected: Bool { get }
    func connect()
    func disconnect()
    func sendAudioData(_ data: Data)
}

// MARK: - AudioEngineManagerProtocol

public protocol AudioEngineManagerProtocol: AnyObject {
    /// Publisher that emits the current audio level (normalized between 0.0 and 1.0).
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
    
    /// Publisher that emits audio buffers for processing (e.g., speech recognition).
    var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> { get }
    
    /// Indicates whether the audio engine is currently running.
    var isEngineRunning: Bool { get }
    
    /// Starts the audio engine.
    func startEngine()
    
    /// Stops the audio engine.
    func stopEngine()
    
    /// Assigns a WebSocket manager for live audio streaming.
    /// - Parameter manager: An object conforming to `WebSocketManagerProtocol`.
    func assignWebSocketManager(manager: WebSocketManagerProtocol)
    
    /// Starts recording audio to a file.
    func startRecording()
    
    /// Stops recording audio to a file.
    func stopRecording()
}

// MARK: - AudioStateProtocol

public protocol AudioStateProtocol: ObservableObject {
    // Recording State
    var isRecording: Bool { get set }
    var isRecordingEnabled: Bool { get set } // Indicates if recording is enabled
    var isBackgroundRecordingEnabled: Bool { get set } // Indicates if background recording is enabled
    
    // Playback State
    var isPlaying: Bool { get set }
    var isPlaybackAvailable: Bool { get set }
    
    // Recording Progress
    var recordingTime: TimeInterval { get set }
    var recordingProgress: Double { get set }
    
    // Current Recording
    var currentRecording: AudioRecording? { get set }
    
    // Error Handling
    var errorMessage: String? { get set }
    
    // Audio Level
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
    var formattedRecordingTime: String { get }
    
    // Recording Control
    func setupWebSocket(manager: WebSocketManagerProtocol)
    func toggleRecording(manual: Bool)
    func stopRecording()
    
    // Playback Control
    func togglePlayback()
    
    // Recording Management
    func deleteRecording(_ recording: AudioRecording)
    func updateLocalRecordings()
    func fetchRecordings()
    
    // Utility
    func formattedFileSize(bytes: Int64) -> String
}

