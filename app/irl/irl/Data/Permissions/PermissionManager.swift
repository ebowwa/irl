//
//  PermissionManager.swift
//  irl
// give the permissions the i as well
//  Created by Elijah Arbee on 9/9/24.
//
import SwiftUI
import Speech
import AVFoundation

class PermissionManager: ObservableObject {
    @Published var isMicrophoneAuthorized: Bool = false
    @Published var isSpeechRecognitionAuthorized: Bool = false
    
    func checkAndRequestPermissions() {
        let micPermission = checkMicrophonePermission()
        let speechPermission = checkSpeechRecognitionPermission()
        
        if micPermission && speechPermission {
            // Proceed with speech recognition and microphone usage
            print("Both microphone and speech recognition permissions granted")
        } else {
            if !micPermission {
                requestMicrophonePermission()
            }
            if !speechPermission {
                requestSpeechRecognitionPermission()
            }
        }
    }
    
    // MARK: - Microphone Permission
    
    private func checkMicrophonePermission() -> Bool {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                isMicrophoneAuthorized = true
                return true
            case .denied, .undetermined:
                isMicrophoneAuthorized = false
                return false
            @unknown default:
                isMicrophoneAuthorized = false
                return false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                isMicrophoneAuthorized = true
                return true
            case .denied, .undetermined:
                isMicrophoneAuthorized = false
                return false
            @unknown default:
                isMicrophoneAuthorized = false
                return false
            }
        }
    }
    
    private func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.handleMicrophonePermissionResult(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.handleMicrophonePermissionResult(granted)
                }
            }
        }
    }
    
    private func handleMicrophonePermissionResult(_ granted: Bool) {
        if granted {
            print("Microphone access granted")
            isMicrophoneAuthorized = true
            // Check if speech recognition is also granted
            if checkSpeechRecognitionPermission() {
                // Proceed with speech recognition and microphone usage
            }
        } else {
            print("User denied access to microphone")
            isMicrophoneAuthorized = false
        }
    }
    
    // MARK: - Speech Recognition Permission
    
    private func checkSpeechRecognitionPermission() -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            isSpeechRecognitionAuthorized = true
            return true
        case .denied, .restricted, .notDetermined:
            isSpeechRecognitionAuthorized = false
            return false
        @unknown default:
            isSpeechRecognitionAuthorized = false
            return false
        }
    }
    
    func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                    self?.isSpeechRecognitionAuthorized = true
                    // Check if microphone is also granted
                    if self?.checkMicrophonePermission() == true {
                        // Proceed with speech recognition and microphone usage
                    }
                case .denied:
                    print("User denied access to speech recognition")
                    self?.isSpeechRecognitionAuthorized = false
                case .restricted:
                    print("Speech recognition restricted on this device")
                    self?.isSpeechRecognitionAuthorized = false
                case .notDetermined:
                    print("Speech recognition not yet authorized")
                    self?.isSpeechRecognitionAuthorized = false
                @unknown default:
                    print("Unknown status")
                    self?.isSpeechRecognitionAuthorized = false
                }
            }
        }
    }
}
