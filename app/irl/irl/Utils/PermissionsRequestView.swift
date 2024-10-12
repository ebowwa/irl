//
//  PermissionsRequestView.swift
//  IRL
//
//  Created by Elijah Arbee on 10/12/24.
//


// Permissions.swift
import SwiftUI
import CoreLocation
import AVFoundation
import Speech

// MARK: - Permissions

// Request camera access permission
func requestCameraPermission() {
    AVCaptureDevice.requestAccess(for: .video) { granted in
        print(granted ? "Camera access granted" : "Camera access denied")
    }
}

// Request microphone access permission
func requestMicPermission() {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
        print(granted ? "Mic access granted" : "Mic access denied")
    }
}

// Request location access permission
func requestLocationPermission() {
    let locationManager = CLLocationManager()
    locationManager.requestWhenInUseAuthorization()
}

// Request speech recognition permission
func requestSpeechRecognitionPermission() {
    SFSpeechRecognizer.requestAuthorization { authStatus in
        switch authStatus {
        case .authorized:
            print("Speech recognition permission granted")
        case .denied, .restricted, .notDetermined:
            print("Speech recognition permission denied")
        @unknown default:
            break
        }
    }
}

// MARK: - SwiftUI Permission Request Trigger View

struct PermissionsRequestView: View {
    @Binding var step: Int // Now this view accepts step as a binding
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Request Location Permission") {
                requestLocationPermission()
            }
            Button("Request Camera Permission") {
                requestCameraPermission()
            }
            Button("Request Microphone Permission") {
                requestMicPermission()
            }
            Button("Request Speech Recognition Permission") {
                requestSpeechRecognitionPermission()
            }
            
            Button("Next") {
                step = 7 // Move to the next step after requesting permissions
            }
        }
        .padding()
    }
}
import AVFoundation
import Speech
import CoreLocation

class PermissionManager: ObservableObject {
    @Published var isMicrophoneAuthorized = false
    @Published var isSpeechRecognitionAuthorized = false
    @Published var isLocationAuthorized = false
    @Published var isCameraAuthorized = false

    private let locationManager = CLLocationManager()

    init() {
        checkPermissions()
    }

    // Check all permissions
    func checkPermissions() {
        checkMicrophonePermission()
        checkSpeechRecognitionPermission()
        checkLocationPermission()
        checkCameraPermission()
    }

    // Request all permissions
    func checkAndRequestPermissions() {
        requestMicrophonePermission()
        requestSpeechRecognitionPermission()
        requestLocationPermission()
        requestCameraPermission()
    }

    // Check microphone permission status
    private func checkMicrophonePermission() {
        let status = AVAudioSession.sharedInstance().recordPermission
        isMicrophoneAuthorized = (status == .granted)
    }

    // Request microphone access permission
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                self.isMicrophoneAuthorized = granted
            }
        }
    }

    // Check speech recognition permission status
    private func checkSpeechRecognitionPermission() {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        isSpeechRecognitionAuthorized = (authStatus == .authorized)
    }

    // Request speech recognition permission
    private func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                self.isSpeechRecognitionAuthorized = (authStatus == .authorized)
            }
        }
    }

    // Check location permission status
    private func checkLocationPermission() {
        let status = CLLocationManager.authorizationStatus()
        isLocationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }

    // Request location access permission
    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        checkLocationPermission()
    }

    // Check camera permission status
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        isCameraAuthorized = (status == .authorized)
    }

    // Request camera access permission
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.isCameraAuthorized = granted
            }
        }
    }
}
