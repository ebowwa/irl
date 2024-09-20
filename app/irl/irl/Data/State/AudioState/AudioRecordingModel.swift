//
//  AudioRecordingModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/7/24.
//

import Foundation
import CoreLocation // For location handling

// MARK: - Models

struct Location {
    let latitude: Double
    let longitude: Double
    let altitude: Double?  // Optional, if available
    let timestamp: Date     // Timestamp of location capture
}

struct DeviceInfo {
    let deviceModel: String       // iPhone, Apple Watch, etc.
    let osVersion: String         // iOS version, etc.
    let deviceType: String?       // AirPods, BLE device, etc.
    let deviceName: String?       // The name of the connected device (if applicable)
}

struct SpeechSegment {
    let startTime: TimeInterval // Timestamp where speech starts
    let endTime: TimeInterval   // Timestamp where speech ends
    let confidence: Double      // Confidence score from the model
}

enum TranscriptionStatus {
    case pending
    case inProgress
    case completed
    case failed
}

struct AudioRecording: Identifiable {
    let id: UUID
    let url: URL
    let creationDate: Date
    let fileSize: Int64
    var isSpeechLikely: Bool?     // Reintroducing isSpeechLikely
    var speechSegments: [SpeechSegment]?  // Segments of detected speech in the recording
    var duration: TimeInterval?           // Total duration of the audio recording
    var location: Location?               // Optional location data if available
    var transcriptionStatus: TranscriptionStatus = .pending // Default to 'pending' when a recording is created
    var ambientNoiseLevel: Double?        // Optional ambient noise level if measured
    var deviceInfo: DeviceInfo?           // Device information, including BLE/Audio devices
    var processedAt: Date?                // Optional timestamp for when transcription is completed
}
