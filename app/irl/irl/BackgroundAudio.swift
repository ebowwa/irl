//
//  BackgroundAudio.swift
//  irl
//
//  Created by Elijah Arbee on 9/22/24.
//
import Foundation
import SwiftUI

class BackgroundAudio: ObservableObject {
    static let shared = BackgroundAudio()
    
    @Published var isRecording: Bool {
        didSet {
            audioState.isRecording = isRecording
        }
    }
    @AppStorage("isRecordingEnabled") private(set) var isRecordingEnabled = false
    @AppStorage("isBackgroundRecordingEnabled") var isBackgroundRecordingEnabled = false
    
    private let audioState: AudioState
    
    private init() {
        self.audioState = AudioState.shared
        self.isRecording = audioState.isRecording
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppBackgrounding), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTermination), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    func toggleRecording() {
        isRecordingEnabled.toggle()
        setupAudioSession()
    }
    
    func setupAudioSession() {
        if isRecordingEnabled {
            if !isRecording {
                startRecording()
            }
        } else {
            if isRecording {
                stopRecording()
            }
        }
    }
    
    func startRecording() {
        audioState.startRecording()
        isRecording = true
    }
    
    func stopRecording() {
        audioState.stopRecording()
        isRecording = false
    }
    
    @objc private func handleAppBackgrounding() {
        if isBackgroundRecordingEnabled {
            setupAudioSession()
        } else {
            stopRecording()
        }
    }
    
    @objc private func handleAppTermination() {
        if isRecording {
            stopRecording()
        }
    }
}
