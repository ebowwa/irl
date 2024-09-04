//  AudioState.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
// AudioState.swift
import Foundation
import AVFoundation
import Combine
import Speech

struct AudioRecording: Identifiable {
    let id: UUID
    let url: URL
    let creationDate: Date
    let fileSize: Int64
    var isSpeechLikely: Bool?
}

class WebSocketManager: WebSocketManagerProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private let receivedDataSubject = PassthroughSubject<Data, Never>()

    var receivedDataPublisher: AnyPublisher<Data, Never> {
        receivedDataSubject.eraseToAnyPublisher()
    }

    init(url: URL) {
        setupWebSocket(url: url)
    }

    private func setupWebSocket(url: URL) {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()

        receiveMessage()
    }

    func sendAudioData(_ data: Data) {
        webSocketTask?.send(.data(data)) { error in
            if let error = error {
                print("Error sending audio data: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self?.receivedDataSubject.send(data)
                    }
                case .data(let data):
                    self?.receivedDataSubject.send(data)
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                print("Error receiving message: \(error)")
            }
        }
    }
}

class AudioState: NSObject, ObservableObject {
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

    private func setupAudioSession() {
        do {
            recordingSession = AVAudioSession.sharedInstance()
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
        }
    }

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

    private func startFileRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")

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

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingTime += 0.1
            self.recordingProgress = min(self.recordingTime / 60.0, 1.0) // Assume max recording time of 60 seconds
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
        audioLevelSubject.send(averagePower)
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func updateCurrentRecording() {
        guard let url = audioRecorder?.url else { return }
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let creationDate = attributes?[.creationDate] as? Date ?? Date()
        let fileSize = attributes?[.size] as? Int64 ?? 0
        
        determineSpeechLikelihood(for: url) { isSpeechLikely in
            DispatchQueue.main.async {
                self.currentRecording = AudioRecording(id: UUID(), url: url, creationDate: creationDate, fileSize: fileSize, isSpeechLikely: isSpeechLikely)
                self.updateLocalRecordings()
            }
        }
    }

    func updateLocalRecordings() {
        do {
            let documentsURL = getDocumentsDirectory()
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: .skipsHiddenFiles)

            localRecordings = fileURLs.compactMap { url -> AudioRecording? in
                guard url.pathExtension == "m4a" else { return nil }
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date ?? Date()
                let fileSize = attributes?[.size] as? Int64 ?? 0
                
                if let existingRecording = localRecordings.first(where: { $0.url == url }) {
                    return AudioRecording(id: UUID(), url: url, creationDate: creationDate, fileSize: fileSize, isSpeechLikely: existingRecording.isSpeechLikely)
                } else {
                    return AudioRecording(id: UUID(), url: url, creationDate: creationDate, fileSize: fileSize, isSpeechLikely: nil)
                }
            }.sorted(by: { $0.creationDate > $1.creationDate })

            for (index, recording) in localRecordings.enumerated() where recording.isSpeechLikely == nil {
                determineSpeechLikelihood(for: recording.url) { isSpeechLikely in
                    DispatchQueue.main.async {
                        self.localRecordings[index].isSpeechLikely = isSpeechLikely
                    }
                }
            }
        } catch {
            errorMessage = "Error fetching local recordings: \(error.localizedDescription)"
        }
    }

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

    func deleteRecording(_ recording: AudioRecording) {
        do {
            try FileManager.default.removeItem(at: recording.url)
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

    var formattedRecordingTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func formattedFileSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

extension AudioState: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        if !flag {
            errorMessage = "Playback finished with an error"
        }
    }
}

protocol WebSocketManagerProtocol {
    func sendAudioData(_ data: Data)
}
