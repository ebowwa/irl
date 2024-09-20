//
//  AudioFileManager.swift
//  irl
//
//  Created by Elijah Arbee on 9/7/24.
//
import Foundation
import AVFoundation

class AudioFileManager {
    static let shared = AudioFileManager()

    private init() {}

    // Returns the URL for the app's document directory
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Updates the list of local audio recordings with the new structure
    func updateLocalRecordings() -> [AudioRecording] {
        do {
            let documentsURL = getDocumentsDirectory()
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )

            // Map over the files to create `AudioRecording` objects
            return fileURLs.compactMap { url -> AudioRecording? in
                guard url.pathExtension == "m4a" else { return nil }

                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date ?? Date()
                let fileSize = attributes?[.size] as? Int64 ?? 0
                let duration = getAudioDuration(for: url)

                // Use isSpeechLikely from your existing logic (which I haven't modified)
                return AudioRecording(
                    id: UUID(),
                    url: url,
                    creationDate: creationDate,
                    fileSize: fileSize,
                    isSpeechLikely: nil,  // Set this based on your existing logic elsewhere
                    speechSegments: nil,    // Default to nil for now, until speech segments are detected
                    duration: duration,     // Calculate duration from AVAsset
                    location: nil,          // Optional, add location if available in future
                    transcriptionStatus: .pending, // Default transcription status
                    ambientNoiseLevel: nil, // Optional, no ambient noise data for now
                    deviceInfo: nil,        // Optional, no device info for now
                    processedAt: nil        // Default to nil until processed
                )
            }.sorted(by: { $0.creationDate > $1.creationDate })  // Sort by creation date
        } catch {
            print("Error fetching local recordings: \(error.localizedDescription)")
            return []
        }
    }

    // Function to delete an audio recording
    func deleteRecording(_ recording: AudioRecording) throws {
        try FileManager.default.removeItem(at: recording.url)
    }

    // Utility to calculate audio duration for a file
    private func getAudioDuration(for url: URL) -> TimeInterval? {
        let asset = AVAsset(url: url)
        let duration = asset.duration
        return duration.seconds.isNaN ? nil : duration.seconds
    }

    // Function to format file size for display
    func formattedFileSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // Function to format duration for display (in minutes and seconds)
    func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
