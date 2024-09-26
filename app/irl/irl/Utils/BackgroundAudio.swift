//
//  BackgroundAudio.swift
//  irl
//
//  Created by Elijah Arbee on 9/22/24.
//
import Foundation
import SwiftUI

// This class handles background audio recording functionality and keeps track of the recording state.
// It conforms to ObservableObject to allow UI components in SwiftUI to react to changes in recording state.
class BackgroundAudio: ObservableObject {

    // Singleton pattern with conditional compilation to make the shared instance flexible for testing.
    #if DEBUG
    // In debug mode, allow the shared instance to be overridden for testing purposes.
    static var shared: BackgroundAudio = BackgroundAudio()
    #else
    // In production, enforce the singleton instance.
    static let shared = BackgroundAudio()
    #endif
    
    // Observable property that indicates if recording is active. When set, it updates the audioState accordingly.
    // @Published allows SwiftUI views to automatically update when this value changes.
    @Published var isRecording: Bool {
        didSet {
            // Synchronize the recording state with the shared AudioState instance.
            audioState.isRecording = isRecording
        }
    }
    
    // Persistent storage for recording-related settings using @AppStorage, allowing the values to be stored and retrieved across app launches.
    // isRecordingEnabled indicates whether recording is toggled on or off.
    @AppStorage("isRecordingEnabled") private(set) var isRecordingEnabled = false
    
    // isBackgroundRecordingEnabled tracks whether recording in the background is allowed.
    @AppStorage("isBackgroundRecordingEnabled") var isBackgroundRecordingEnabled = false
    
    // Reference to a shared instance of AudioState, which handles the low-level audio recording functionality.
    private var audioState: AudioState
    
    // Private initializer enforces the singleton pattern and sets up initial states and notifications.
    // This initializer can be customized with an injected instance of `AudioState` to enable testing flexibility.
    private init(audioState: AudioState = AudioState.shared) {
        // Initialize the audioState from the injected or default shared instance.
        self.audioState = audioState
        
        // Set the local recording state to match the initial state from audioState.
        self.isRecording = audioState.isRecording
        
        // Set up listeners for app lifecycle notifications like backgrounding and termination.
        setupNotifications()
    }
    
    // Factory method to return the shared instance, allowing flexibility during testing.
    static func getInstance(forTesting testInstance: AudioState? = nil) -> BackgroundAudio {
        if let testAudioState = testInstance {
            return BackgroundAudio(audioState: testAudioState)
        }
        return BackgroundAudio.shared
    }

    // Registers for system notifications related to the app's lifecycle.
    private func setupNotifications() {
        // Listen for when the app is about to go into the background (resign active).
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppBackgrounding), name: UIApplication.willResignActiveNotification, object: nil)
        
        // Listen for when the app is about to terminate.
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTermination), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    // Toggles the recording functionality and sets up or tears down the audio session accordingly.
    func toggleRecording() {
        // Flip the current recording enabled state.
        isRecordingEnabled.toggle()
        
        // Adjust the audio session based on the new state.
        setupAudioSession()
    }
    
    // Sets up the audio session based on the isRecordingEnabled state.
    func setupAudioSession() {
        if isRecordingEnabled {
            // If recording is enabled but not currently recording, start it.
            if !isRecording {
                startRecording()
            }
        } else {
            // If recording is disabled and the audio session is active, stop recording.
            if isRecording {
                stopRecording()
            }
        }
    }
    
    // Starts the recording process by invoking the audioState's startRecording function and setting isRecording to true.
    func startRecording() {
        // Delegate the recording start to audioState.
        audioState.startRecording()
        
        // Update the recording state to reflect the change.
        isRecording = true
    }
    
    // Stops the recording process by invoking the audioState's stopRecording function and setting isRecording to false.
    func stopRecording() {
        // Delegate the recording stop to audioState.
        audioState.stopRecording()
        
        // Update the recording state to reflect the change.
        isRecording = false
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
}
