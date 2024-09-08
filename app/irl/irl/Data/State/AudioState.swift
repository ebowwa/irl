//  AudioState.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
import Foundation
import AVFoundation
import Combine
import Speech

class AudioState: NSObject, AudioStateProtocol {
    static let shared = AudioState()

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingTime: TimeInterval = 0
    @Published var recordingProgress: Double = 0
    @Published var currentRecording: AudioRecording?
    @Published var isPlaybackAvailable = false
    @Published var errorMessage: String?
    @Published var localRecordings: [AudioRecording] = []

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    private var recordingTimer: Timer?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    private var audioEngine: AVAudioEngine?
    private var webSocketManager: WebSocketManagerProtocol?
    private let audioBufferSize: AVAudioFrameCount = 1024

    private var cancellables: Set<AnyCancellable> = []

    override init() {
        super.init()
        setupAudioSession()
        updateLocalRecordings()
    }

    func setupWebSocket(manager: WebSocketManagerProtocol) {
        self.webSocketManager = manager
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            recordingSession = AVAudioSession.sharedInstance()
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
        }
    }

    // MARK: - Recording Controls

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        if webSocketManager != nil {
            startLiveStreaming()
        } else {
            startFileRecording()
        }
    }

    func stopRecording() {
        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            self.audioEngine = nil
        } else {
            audioRecorder?.stop()
        }

        isRecording = false
        stopRecordingTimer()
        updateCurrentRecording()
        updateLocalRecordings()
        isPlaybackAvailable = true
    }

    // MARK: - Live Streaming

    private func startLiveStreaming() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            errorMessage = "Failed to create audio engine"
            return
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: audioBufferSize, format: inputFormat) { [weak self] (buffer, time) in
            self?.processMicrophoneBuffer(buffer: buffer, time: time)
        }

        do {
            try audioEngine.start()
            isRecording = true
            recordingTime = 0
            recordingProgress = 0
            startRecordingTimer()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }

    private func processMicrophoneBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let channelData = buffer.floatChannelData else { return }
        let frames = buffer.frameLength

        var data = Data(capacity: Int(frames) * MemoryLayout<Float>.size)
        for i in 0..<Int(frames) {
            var sample = channelData[0][i]
            data.append(Data(bytes: &sample, count: MemoryLayout<Float>.size))
        }

        webSocketManager?.sendAudioData(data)
    }

    // MARK: - File Recording

    private func startFileRecording() {
        let audioFilename = AudioFileManager.shared.getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            isRecording = true
            recordingTime = 0
            recordingProgress = 0
            startRecordingTimer()
            errorMessage = nil
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }

    // MARK: - Recording Timer
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.recordingTime += 0.1
                self.updateAudioLevels()
            }
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
        audioLevelSubject.send(averagePower)
    }

    // MARK: - File Management

    private func updateCurrentRecording() {
        guard let url = audioRecorder?.url else { return }
        let fileManager = AudioFileManager.shared
        let recordings = fileManager.updateLocalRecordings()
        currentRecording = recordings.first { $0.url == url }
        
        if let recording = currentRecording {
            determineSpeechLikelihood(for: recording.url) { isSpeechLikely in
                DispatchQueue.main.async {
                    self.currentRecording?.isSpeechLikely = isSpeechLikely
                    self.updateLocalRecordings()
                }
            }
        }
    }

    func updateLocalRecordings() {
        let updatedRecordings = AudioFileManager.shared.updateLocalRecordings()
        
        for recording in updatedRecordings {
            if recording.isSpeechLikely == nil {
                determineSpeechLikelihood(for: recording.url) { [weak self] isSpeechLikely in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let index = self.localRecordings.firstIndex(where: { $0.url == recording.url }) {
                            self.localRecordings[index].isSpeechLikely = isSpeechLikely
                        }
                    }
                }
            }
        }
        
        self.localRecordings = updatedRecordings
    }
    
    func fetchRecordings() {
        updateLocalRecordings()
    }

    func deleteRecording(_ recording: AudioRecording) {
        do {
            try AudioFileManager.shared.deleteRecording(recording)
            updateLocalRecordings()

            if currentRecording?.url == recording.url {
                currentRecording = nil
                isPlaybackAvailable = false
            }

            errorMessage = nil
        } catch {
            errorMessage = "Error deleting recording: \(error.localizedDescription)"
        }
    }

    // MARK: - Speech Recognition

    private func determineSpeechLikelihood(for url: URL, completion: @escaping (Bool) -> Void) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        speechRecognizer?.recognitionTask(with: request) { result, error in
            guard let result = result else {
                completion(false)
                return
            }
            
            let isSpeechLikely = result.bestTranscription.formattedString.split(separator: " ").count > 1 && result.bestTranscription.segments.first?.confidence ?? 0 > 0.5
            completion(isSpeechLikely)
        }
    }

    // MARK: - Playback Controls

    func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }

    private func startPlayback() {
        guard let recording = currentRecording else {
            errorMessage = "No recording available to play"
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            errorMessage = nil
        } catch {
            errorMessage = "Error playing audio: \(error.localizedDescription)"
        }
    }

    private func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
    }

    // MARK: - Formatting Helpers

    var formattedRecordingTime: String {
        AudioFileManager.shared.formattedDuration(recordingTime)
    }

    func formattedFileSize(bytes: Int64) -> String {
        AudioFileManager.shared.formattedFileSize(bytes: bytes)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioState: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        if !flag {
            errorMessage = "Playback finished with an error"
        }
    }
}
