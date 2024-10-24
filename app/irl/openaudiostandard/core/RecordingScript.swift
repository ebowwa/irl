//
//  RecordingScript.swift
//  IRL
//
//  Created by Elijah Arbee on 10/23/24.
//


import Foundation
import AVFoundation
import Combine

class RecordingScript {
    private let audioEngineManager = AudioEngineManager.shared
    private var audioLevelSubscription: AnyCancellable?
    private var audioBufferSubscription: AnyCancellable?

    init() {
        // Subscribe to the audio level updates
        audioLevelSubscription = audioEngineManager.audioLevelPublisher
            .sink { audioLevel in
                print("Audio Level: \(audioLevel) dB")
            }
        
        // Subscribe to audio buffer updates
        audioBufferSubscription = audioEngineManager.audioBufferPublisher
            .sink { buffer in
                print("Audio buffer received with frame length: \(buffer.frameLength)")
            }
        
        // Initialize the engine and prepare for recording
        setupAudioSession()
        audioEngineManager.startEngine()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("Audio session is set up successfully.")
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    // Start recording to a file
    func startRecording() {
        print("Starting recording...")
        audioEngineManager.startRecording()
    }
    
    // Stop recording
    func stopRecording() {
        print("Stopping recording...")
        audioEngineManager.stopRecording()
    }
    
    // Start streaming
    func startStreaming() {
        print("Starting audio engine and streaming...")
        audioEngineManager.startEngine()
    }
    
    // Stop streaming
    func stopStreaming() {
        print("Stopping audio engine and streaming...")
        audioEngineManager.stopEngine()
    }
    
    // Cleanup resources when done
    deinit {
        audioLevelSubscription?.cancel()
        audioBufferSubscription?.cancel()
        audioEngineManager.stopEngine()
        print("Recording script cleanup completed.")
    }
}
