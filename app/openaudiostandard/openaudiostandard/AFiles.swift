//
//  AFiles.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/23/24.
//

import Foundation

// imports audiorecordingmodel
public class AudioFileManager {
    public static let shared = AudioFileManager()
    
    private init() {}
    
    /// Returns the documents directory URL.
    public func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Updates and returns the list of local recordings.
    public func updateLocalRecordings() -> [AudioRecording] {
        let documents = getDocumentsDirectory()
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil, options: [])
            let recordings = files.filter { $0.pathExtension == "m4a" }.map { AudioRecording(url: $0) }
            return recordings.sorted(by: { $0.url.lastPathComponent > $1.url.lastPathComponent })
        } catch {
            print("Failed to list recordings: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Deletes a specific recording.
    public func deleteRecording(_ recording: AudioRecording) throws {
        try FileManager.default.removeItem(at: recording.url)
    }
    
    /// Formats a duration to a string (MM:SS).
    public func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// Formats file size to a readable string.
    public func formattedFileSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB] // Adjust as needed
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
