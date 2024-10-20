//
//  AudioFileManager.swift
//  IRL-AudioCore
//
//  Created by Elijah Arbee on 10/20/24.
//


//
//  AudioFileManager.swift
//  AudioFramework
//
//  Created by Elijah Arbee on 9/7/24.
//

import Foundation
import AVFoundation

public class AudioFileManager {
    public static let shared = AudioFileManager()

    private init() {}

    /// Returns the URL for the framework's document directory
    public func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Updates the list of local audio recordings
    public func updateLocalRecordings() -> [AudioRecording] {
        do {
            let documentsURL = getDocumentsDirectory()
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )

            return fileURLs.compactMap { url -> AudioRecording? in
                guard url.pathExtension == "m4a" else { return nil }
                
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date ?? Date()
                let fileSize = attributes?[.size] as? Int64 ?? 0
                let duration = getAudioDuration(for: url)

                return AudioRecording(
                    id: UUID(),
                    url: url,
                    creationDate: creationDate,
                    fileSize: fileSize,
                    isSpeechLikely: nil,  // Add logic elsewhere for determining speech likelihood
                    speechSegments: nil,  // Set when speech segments are detected
                    duration: duration,
                    location: nil,  // Add location if available in the future
                    transcriptionStatus: .pending,
                    ambientNoiseLevel: nil,
                    deviceInfo: nil,
                    processedAt: nil
                )
            }.sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("Error fetching local recordings: \(error.localizedDescription)")
            return []
        }
    }

    /// Deletes an audio recording
    public func deleteRecording(_ recording: AudioRecording) throws {
        try FileManager.default.removeItem(at: recording.url)
    }

    /// Returns the duration of the audio file
    private func getAudioDuration(for url: URL) -> TimeInterval? {
        let asset = AVAsset(url: url)
        let duration = asset.duration
        return duration.seconds.isNaN ? nil : duration.seconds
    }

    /// Formats the file size for display
    public func formattedFileSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Formats the duration for display in minutes and seconds
    public func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AudioRecording Struct

public struct AudioRecording: Identifiable, Codable {
    public let id: UUID
    public let url: URL
    public let creationDate: Date
    public let fileSize: Int64
    public var isSpeechLikely: Bool?
    public var speechSegments: [String]?
    public let duration: TimeInterval?
    public let location: LocationData?
    public var transcriptionStatus: TranscriptionStatus
    public var ambientNoiseLevel: Double?
    public var deviceInfo: String?
    public var processedAt: Date?

    public init(id: UUID = UUID(),
                url: URL,
                creationDate: Date,
                fileSize: Int64,
                isSpeechLikely: Bool? = nil,
                speechSegments: [String]? = nil,
                duration: TimeInterval? = nil,
                location: LocationData? = nil,
                transcriptionStatus: TranscriptionStatus = .pending,
                ambientNoiseLevel: Double? = nil,
                deviceInfo: String? = nil,
                processedAt: Date? = nil) {
        self.id = id
        self.url = url
        self.creationDate = creationDate
        self.fileSize = fileSize
        self.isSpeechLikely = isSpeechLikely
        self.speechSegments = speechSegments
        self.duration = duration
        self.location = location
        self.transcriptionStatus = transcriptionStatus
        self.ambientNoiseLevel = ambientNoiseLevel
        self.deviceInfo = deviceInfo
        self.processedAt = processedAt
    }
}

// MARK: - TranscriptionStatus Enum

public enum TranscriptionStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}
