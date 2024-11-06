/** // AudioRecorder.swift
import Foundation
import AVFoundation
import Combine

/// AudioRecorder manages audio recording and saving as WAV.
class AudioRecorder: NSObject, ObservableObject {
    // Published properties to notify the UI of changes.
    @Published var isRecording = false
    @Published var recordingURL: URL?
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    
    /// Starts recording audio and saves it as WAV.
    func startRecording() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.setupAndStartRecording()
                } else {
                    self?.errorMessage = "Microphone access denied."
                }
            }
        }
    }
    
    /// Stops the ongoing audio recording.
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    /// Sets up the audio session and starts recording.
    private func setupAndStartRecording() {
        do {
            // Configure the audio session for recording.
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            
            // Define the recording settings for WAV format.
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]
            
            // Create a unique file name and URL for the recording.
            let filename = UUID().uuidString + ".wav"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            self.recordingURL = fileURL
            
            // Initialize the AVAudioRecorder.
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            errorMessage = nil
        } catch {
            print("Failed to set up recording: \(error.localizedDescription)")
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Recording was not successful."
        }
    }
}
*/
