//
//  SFSpeechRecognizer.swift
//  irl
//
//  Created by Elijah Arbee on 9/7/24.
//
import Speech
import AVFoundation
import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkAndRequestPermissions()
    }
    
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
    
    func checkMicrophonePermission() -> Bool {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                return true
            case .denied, .undetermined:
                return false
            @unknown default:
                return false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                return true
            case .denied, .undetermined:
                return false
            @unknown default:
                return false
            }
        }
    }
    
    func requestMicrophonePermission() {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.handleMicrophonePermissionResult(granted)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.handleMicrophonePermissionResult(granted)
                }
            }
        }
    }
    
    private func handleMicrophonePermissionResult(_ granted: Bool) {
        if granted {
            print("Microphone access granted")
            // Check if speech recognition is also granted
            if self.checkSpeechRecognitionPermission() {
                // Proceed with speech recognition and microphone usage
            }
        } else {
            print("User denied access to microphone")
            self.showPermissionDeniedAlert(for: "Microphone")
        }
    }
    
    // MARK: - Speech Recognition Permission
    
    func checkSpeechRecognitionPermission() -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            return true
        case .denied, .restricted, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }
    
    func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                    // Check if microphone is also granted
                    if self.checkMicrophonePermission() {
                        // Proceed with speech recognition and microphone usage
                    }
                case .denied:
                    print("User denied access to speech recognition")
                    self.showPermissionDeniedAlert(for: "Speech Recognition")
                case .restricted:
                    print("Speech recognition restricted on this device")
                    self.showPermissionDeniedAlert(for: "Speech Recognition")
                case .notDetermined:
                    print("Speech recognition not yet authorized")
                @unknown default:
                    print("Unknown status")
                }
            }
        }
    }
    
    // MARK: - Alert
    
    func showPermissionDeniedAlert(for permission: String) {
        let alert = UIAlertController(title: "Permission Required", message: "\(permission) access is required. Please enable it in the Settings app.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}
