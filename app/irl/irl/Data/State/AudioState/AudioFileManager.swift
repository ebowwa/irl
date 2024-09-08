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
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func updateLocalRecordings() -> [AudioRecording] {
        do {
            let documentsURL = getDocumentsDirectory()
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: .skipsHiddenFiles)
            
            return fileURLs.compactMap { url -> AudioRecording? in
                guard url.pathExtension == "m4a" else { return nil }
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date ?? Date()
                let fileSize = attributes?[.size] as? Int64 ?? 0
                let duration = getAudioDuration(for: url)
                
                return AudioRecording(id: UUID(), url: url, creationDate: creationDate, fileSize: fileSize, isSpeechLikely: nil, duration: duration)
            }.sorted(by: { $0.creationDate > $1.creationDate })
        } catch {
            print("Error fetching local recordings: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteRecording(_ recording: AudioRecording) throws {
        try FileManager.default.removeItem(at: recording.url)
    }
    
    private func getAudioDuration(for url: URL) -> TimeInterval? {
        let asset = AVAsset(url: url)
        let duration = asset.duration
        return duration.seconds.isNaN ? nil : duration.seconds
    }
    
    func formattedFileSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
