//
//  IrlAudioConfiguration.swift
//  irl
//
//  Created by Elijah Arbee on 10/7/24.
//
import Foundation
import AVFoundation

/// Enum representing audio quality levels.
enum IrlAudioQuality: String, Codable {
    case min
    case low
    case medium
    case high
    case max

    /// Maps to AVAudioQuality raw values.
    var avQuality: AVAudioQuality {
        switch self {
        case .min:
            return .min
        case .low:
            return .low
        case .medium:
            return .medium
        case .high:
            return .high
        case .max:
            return .max
        }
    }
}

/// Enum representing AVAudioSession categories.
enum IrlAudioSessionCategory: String, Codable {
    case ambient
    case soloAmbient
    case playback
    case record
    case playAndRecord
    case multiRoute

    /// Converts to AVAudioSession.Category.
    var avCategory: AVAudioSession.Category {
        switch self {
        case .ambient:
            return .ambient
        case .soloAmbient:
            return .soloAmbient
        case .playback:
            return .playback
        case .record:
            return .record
        case .playAndRecord:
            return .playAndRecord
        case .multiRoute:
            return .multiRoute
        }
    }
}

/// Enum representing AVAudioSession modes.
enum IrlAudioSessionMode: String, Codable {
    case `default`
    case voiceChat
    case videoRecording
    case measurement
    case gameChat
    case videoChat
    case spokenAudio

    /// Converts to AVAudioSession.Mode.
    var avMode: AVAudioSession.Mode {
        switch self {
        case .default:
            return .default
        case .voiceChat:
            return .voiceChat
        case .videoRecording:
            return .videoRecording
        case .measurement:
            return .measurement
        case .gameChat:
            return .gameChat
        case .videoChat:
            return .videoChat
        case .spokenAudio:
            return .spokenAudio
        }
    }
}

/// Struct to hold all audio configuration settings.
struct IrlAudioConfiguration: Codable {
    let audioFormat: String
    let sampleRate: Double
    let channels: Int
    let quality: IrlAudioQuality
    let bitRate: Int
    let bitDepth: Int
    let bufferDuration: Double
    let audioSessionCategory: IrlAudioSessionCategory
    let audioSessionMode: IrlAudioSessionMode
    let audioSessionOptions: [String]

    /// Converts the configuration to AVAudioRecorder settings.
    func toAVAudioRecorderSettings() -> [String: Any] {
        var settings: [String: Any] = [
            AVFormatIDKey: getAVFormatID(),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVEncoderAudioQualityKey: quality.avQuality.rawValue,
            AVEncoderBitRateKey: bitRate
        ]

        // If the format is Linear PCM, add bit depth and other relevant settings.
        if getAVFormatID() == kAudioFormatLinearPCM {
            settings[AVLinearPCMBitDepthKey] = bitDepth
            settings[AVLinearPCMIsBigEndianKey] = false
            settings[AVLinearPCMIsFloatKey] = false
        }

        return settings
    }

    /// Maps string format ID to AudioFormatID.
    private func getAVFormatID() -> AudioFormatID {
        switch audioFormat {
        case "kAudioFormatMPEG4AAC":
            return kAudioFormatMPEG4AAC
        case "kAudioFormatLinearPCM":
            return kAudioFormatLinearPCM
        // Add more cases as needed.
        default:
            print("IrlAudioConfiguration: Unknown audio format '\(audioFormat)', defaulting to AAC.")
            return kAudioFormatMPEG4AAC
        }
    }

    /// Converts string options to AVAudioSession.CategoryOptions.
    func getAVAudioSessionOptions() -> AVAudioSession.CategoryOptions {
        var options: AVAudioSession.CategoryOptions = []
        for option in audioSessionOptions {
            switch option {
            case "mixWithOthers":
                options.insert(.mixWithOthers)
            case "duckOthers":
                options.insert(.duckOthers)
            case "allowBluetooth":
                options.insert(.allowBluetooth)
            case "allowBluetoothA2DP":
                options.insert(.allowBluetoothA2DP)
            case "defaultToSpeaker":
                options.insert(.defaultToSpeaker)
            case "interruptSpokenAudioAndMixWithOthers":
                options.insert(.interruptSpokenAudioAndMixWithOthers)
            default:
                print("IrlAudioConfiguration: Unknown audio session option '\(option)'.")
            }
        }
        return options
    }

    /// Encodes the configuration to JSON Data.
    func toJSONData() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            return data
        } catch {
            print("IrlAudioConfiguration: Failed to encode to JSON with error: \(error)")
            return nil
        }
    }

    /// Encodes the configuration to a JSON String.
    func toJSONString() -> String? {
        guard let data = toJSONData() else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
