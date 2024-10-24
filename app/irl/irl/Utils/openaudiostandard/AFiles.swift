//
//  AFiles.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/23/24.
//

import Foundation
import AVFoundation

public class AudioFileManager {
    public static let shared = AudioFileManager()
    
    private init() {}
    
    /// Returns the documents directory URL.
    public func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Updates and returns the list of local recordings for .m4a, .caf, and .wav formats.
    public func updateLocalRecordings() -> [AudioRecording] {
        let documents = getDocumentsDirectory()
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil, options: [])
            let supportedExtensions = ["m4a", "caf", "wav"]
            let recordings = files.filter { supportedExtensions.contains($0.pathExtension) }
                                   .map { AudioRecording(url: $0) }
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
    
    /// Saves an audio recording in the specified format: .m4a, .caf, or .wav.
    public func saveRecording(_ inputURL: URL, format: String, outputURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        let asset = AVAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            completion(false, NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create export session"]))
            return
        }
        
        switch format {
        case "m4a":
            exportSession.outputFileType = .m4a
        case "caf":
            exportSession.outputFileType = .caf
        case "wav":
            exportSession.outputFileType = .wav
        default:
            completion(false, NSError(domain: "FormatError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported format"]))
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                completion(true, nil)
            case .failed, .cancelled:
                completion(false, exportSession.error)
            default:
                completion(false, NSError(domain: "ExportError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Export failed for unknown reasons"]))
            }
        }
    }
}
