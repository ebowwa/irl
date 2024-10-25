//
//  RecordingScript.swift
//  IRL
//
//  Created by Elijah Arbee on 10/23/24.
//

import Foundation
import AVFoundation
import Combine

// MARK: - RecordingScript Class

public class RecordingScript: NSObject, RecordingManagerProtocol {
    // MARK: - Publishers
    @Published private(set) public var isRecordingState: Bool = false
    @Published private(set) public var recordingTimeValue: TimeInterval = 0
    @Published private(set) public var recordingProgressValue: Double = 0
    @Published private(set) public var errorMessageValue: String?
    
    // MARK: - Protocol Conformance
    public var isRecording: AnyPublisher<Bool, Never> {
        $isRecordingState.eraseToAnyPublisher()
    }
    
    public var recordingTime: AnyPublisher<TimeInterval, Never> {
        $recordingTimeValue.eraseToAnyPublisher()
    }
    
    public var recordingProgress: AnyPublisher<Double, Never> {
        $recordingProgressValue.eraseToAnyPublisher()
    }
    
    public var errorMessage: AnyPublisher<String?, Never> {
        $errorMessageValue.eraseToAnyPublisher()
    }
    
    // MARK: - Properties
    private let audioEngineManager = AudioEngineManager.shared
    private var audioLevelSubscription: AnyCancellable?
    private var audioBufferSubscription: AnyCancellable?
    private var recordingTimer: Timer?
    fileprivate var audioRecorder: AVAudioRecorder? // Changed to 'fileprivate' for extension access
    
    // MARK: - Initialization
    public override init() {
        super.init()
        // Subscribe to the audio level updates
        audioLevelSubscription = audioEngineManager.audioLevelPublisher
            .sink { [weak self] audioLevel in
                print("Audio Level: \(audioLevel) dB")
                self?.recordingProgressValue = Double(audioLevel)
            }
        
        // Subscribe to audio buffer updates
        audioBufferSubscription = audioEngineManager.audioBufferPublisher
            .sink { buffer in
                print("Audio buffer received with frame length: \(buffer.frameLength)")
            }
        
        // Initialize the engine and prepare for recording
        setupAudioSession()
        audioEngineManager.startEngine()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("Audio session is set up successfully.")
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            self.errorMessageValue = "Failed to set up audio session: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Recording Controls
    public func startRecording() { // Implementing the protocol method without 'manual' parameter
        print("Starting recording...")
        guard !isRecordingState else {
            print("Already recording.")
            return
        }
        
        // Define the recording settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000, // 16 kHz is recommended for speech recognition
            AVNumberOfChannelsKey: 1, // Mono channel is sufficient for speech
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Define the file URL for recording
        let audioFilename = AudioFileManager.shared.getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            isRecordingState = true
            recordingTimeValue = 0
            recordingProgressValue = 0
            startRecordingTimer()
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
            self.errorMessageValue = "Could not start recording: \(error.localizedDescription)"
        }
    }

    public func stopRecording() {
        print("Stopping recording...")
        guard isRecordingState else {
            print("Not currently recording.")
            return
        }

        audioRecorder?.stop()
        audioRecorder = nil
        isRecordingState = false
        stopRecordingTimer()
    }

    // MARK: - Recording Timer
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isRecordingState else { return }
            self.recordingTimeValue += 1.0
            self.updateAudioLevels()
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func updateAudioLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters()
        let averagePower = recorder.averagePower(forChannel: 0)
        let progress = mapAudioLevelToProgress(averagePower)
        recordingProgressValue = progress
    }

    private func mapAudioLevelToProgress(_ averagePower: Float) -> Double {
        // Example mapping from decibels (-160 dB to 0 dB) to progress (0.0 to 1.0)
        let minDb: Float = -160
        let maxDb: Float = 0
        let normalized = (averagePower - minDb) / (maxDb - minDb)
        return Double(max(0, min(1, normalized)))
    }

    // MARK: - Deinitialization
    deinit {
        audioLevelSubscription?.cancel()
        audioBufferSubscription?.cancel()
        audioEngineManager.stopEngine()
        print("Recording script cleanup completed.")
    }
}

// MARK: - AVAudioRecorderDelegate
extension RecordingScript: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessageValue = "Recording did not finish successfully."
                self?.isRecordingState = false
            }
        }
    }

    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessageValue = "Recording encoding error: \(error.localizedDescription)"
                self?.isRecordingState = false
            }
        }
    }
}

// MARK: - Extension to Expose Recording URL
extension RecordingScript {
    public func currentRecordingURL() -> URL? {
        return audioRecorder?.url
    }
}


// ARecordingModel.swift
// openaudiostandard
//
// Created by Elijah Arbee on 10/23/24.
//

import Foundation

public struct AudioRecording: Identifiable {
    public let id: UUID
    public let url: URL
    public var isSpeechLikely: Bool?
    
    public init(id: UUID = UUID(), url: URL, isSpeechLikely: Bool? = nil) {
        self.id = id
        self.url = url
        self.isSpeechLikely = isSpeechLikely
    }
}

