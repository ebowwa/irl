//
//  AudioRecordingManager.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/23/24.
//


// AudioRecordingManager.swift
import Foundation
import AVFoundation
import Combine

public class AudioRecordingManager: NSObject, AVAudioRecorderDelegate, ObservableObject {
    
    // Published properties
    @Published public private(set) var isRecording: Bool = false
    @Published public private(set) var recordingTime: TimeInterval = 0
    @Published public private(set) var recordingProgress: Double = 0
    @Published public var errorMessage: String?
    
    // Private properties
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var cancellables: Set<AnyCancellable> = []
    public var currentRecordingURL: URL?
    public var isManualRecording: Bool = false
    private var webSocketManager: WebSocketManagerProtocol?
    
    // Initialization
    public override init() {
        super.init()
    }
    
    // Assign WebSocket Manager
    public func assignWebSocketManager(manager: WebSocketManagerProtocol) {
        self.webSocketManager = manager
    }
    
    // Start Recording
    public func startRecording(withSettings settings: [String: Any], manual: Bool) {
        guard !isRecording else { return }
        isManualRecording = manual
        let audioFilename = AudioFileManager.shared.getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            currentRecordingURL = audioFilename
            isRecording = true
            recordingTime = 0
            recordingProgress = 0
            startRecordingTimer()
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            print("AudioRecordingManager Error: \(error.localizedDescription)")
        }
    }
    
    // Stop Recording
    public func stopRecording() {
        guard isRecording else { return }
        audioRecorder?.stop()
        stopRecordingTimer()
        isRecording = false
        isManualRecording = false
        audioRecorder = nil
    }
    
    // Recording Timer
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }
            self.recordingTime += 0.1
            recorder.updateMeters()
            let averagePower = recorder.averagePower(forChannel: 0)
            self.recordingProgress = self.mapAudioLevelToProgress(averagePower)
            
            // If WebSocket is connected, send audio data
            if let manager = self.webSocketManager, manager.isConnected {
                if let data = self.fetchAudioData() {
                    manager.sendAudioData(data)
                }
            }
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // Map Audio Level
    private func mapAudioLevelToProgress(_ averagePower: Float) -> Double {
        let minDb: Float = -160
        let maxDb: Float = 0
        let normalized = (averagePower - minDb) / (maxDb - minDb)
        return Double(max(0, min(1, normalized)))
    }
    
    // Fetch Audio Data (Placeholder)
    private func fetchAudioData() -> Data? {
        // Implement actual audio data fetching if streaming is required
        // This might involve accessing the audio buffer or file
        return nil
    }
    
    // AVAudioRecorderDelegate Methods
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Recording did not finish successfully."
            isRecording = false
        }
    }
    
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            errorMessage = "Recording encoding error: \(error.localizedDescription)"
            isRecording = false
        }
    }
}
