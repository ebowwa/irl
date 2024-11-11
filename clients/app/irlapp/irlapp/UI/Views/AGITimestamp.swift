//
//  WebsocketAudioView.swift
//   CaringMind
//
//  Created by Elijah Arbee on 11/10/24.
//
//
//  AGITimestamp.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/10/24.
//

// the audio files shouldnt erase automatically, rather we should take advantage of googles media uploads, this will allow revisiting audio data with additional questions or tasks later on

// this seems to only allow processing once

// MARK: - Audio Recording Service
import SwiftUI
import AVFoundation

// MARK: - Models
struct AGITimestamp: Codable {
    let start: Double
    let end: Double
}

struct AGISegment: Codable, Identifiable {
    let id = UUID()
    let timestamp: AGITimestamp
    let speaker: String
    let transcription: String
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, speaker, transcription
    }
}

// MARK: - Audio Recording Service
class AudioRecorder: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    private var audioFile: AVAudioFile?
    private var converter: AVAudioConverter?
    private let desiredSampleRate: Double = 16000.0 // Adjust as per server requirements
    private let desiredChannels: AVAudioChannelCount = 1 // Mono recording
    
    @Published var isRecording = false
    
    override init() {
        super.init()
        configureAudioSession()
        setupAudioEngine()
        setupInterruptionHandling()
    }
    
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setPreferredSampleRate(desiredSampleRate)
            try audioSession.setPreferredInputNumberOfChannels(Int(desiredChannels))
            try audioSession.setActive(true)
            
            let actualSampleRate = audioSession.sampleRate
            let actualChannelCount = audioSession.inputNumberOfChannels
            print("Actual Sample Rate: \(actualSampleRate)")
            print("Actual Channel Count: \(actualChannelCount)")
        } catch {
            print("Error configuring AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("Recording Format - Sample Rate: \(recordingFormat.sampleRate), Channels: \(recordingFormat.channelCount)")
        
        guard recordingFormat.channelCount > 0 else {
            fatalError("Invalid channel count in recording format.")
        }
        
        guard let desiredFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: desiredSampleRate,
            channels: desiredChannels,
            interleaved: false
        ) else {
            fatalError("Failed to create desired AVAudioFormat.")
        }
        
        if recordingFormat.sampleRate != desiredSampleRate || recordingFormat.channelCount != desiredChannels {
            converter = AVAudioConverter(from: recordingFormat, to: desiredFormat)
            if converter == nil {
                print("Failed to initialize AVAudioConverter.")
            }
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 512, format: recordingFormat) { [weak self] buffer, time in
            guard let self = self, let audioFile = self.audioFile else { return }
            
            if let converter = self.converter {
                DispatchQueue.global(qos: .userInitiated).async {
                    guard let convertedBuffer = AVAudioPCMBuffer(
                        pcmFormat: desiredFormat,
                        frameCapacity: AVAudioFrameCount(desiredFormat.sampleRate * Double(buffer.frameLength) / recordingFormat.sampleRate)
                    ) else {
                        print("Failed to create converted buffer.")
                        return
                    }
                    
                    var error: NSError?
                    let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: { inNumPackets, outStatus in
                        outStatus.pointee = .haveData
                        return buffer
                    })
                    
                    if status == .haveData {
                        do {
                            try audioFile.write(from: convertedBuffer)
                        } catch {
                            print("Error writing converted buffer: \(error.localizedDescription)")
                        }
                    } else {
                        if let error = error {
                            print("Conversion failed: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try audioFile.write(from: buffer)
                    } catch {
                        print("Error writing buffer: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func startRecording() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording.wav")
        
        guard let desiredFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: desiredSampleRate,
            channels: desiredChannels,
            interleaved: false
        ) else {
            fatalError("Failed to create desired AVAudioFormat.")
        }
        
        do {
            audioFile = try AVAudioFile(forWriting: audioFilename, settings: desiredFormat.settings)
            try audioEngine.start()
            isRecording = true
            print("Recording started.")
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
            throw error
        }
    }
    
    func stopRecording() -> URL? {
        guard let audioFile = audioFile else { return nil }
        
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isRecording = false
        print("Recording stopped.")
        
        return audioFile.url
    }
    
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            if isRecording {
                stopRecording()
            }
        } else if type == .ended {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Error reactivating AVAudioSession: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - WebSocket Service
@MainActor
class AGIViewModel: ObservableObject {
    @Published var transcription = ""
    @Published var isConnected = false
    @Published var isProcessing = false
    @Published var error: String?
    @Published var segments: [AGISegment] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let serverURL: String
    private let audioRecorder = AudioRecorder()
    
    var isRecording: Bool { audioRecorder.isRecording }
    
    init(serverURL: String) {
        self.serverURL = serverURL
        setupWebSocket()
    }
    
    private func setupWebSocket() {
        guard let url = URL(string: serverURL) else {
            error = "Invalid WebSocket URL."
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        receiveMessages()
    }
    
    // Add this new structure to match the server response
    struct TranscriptionResponse: Codable {
        let status: String
        let transcriptions: [AGISegment]
    }

    // Update the receiveMessages function in AGIViewModel
    private func receiveMessages() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("Received WebSocket message: \(text)")
                        if let data = text.data(using: .utf8),
                           let response = try? JSONDecoder().decode(TranscriptionResponse.self, from: data) {
                            self?.segments = response.transcriptions // Replace existing segments
                            self?.isProcessing = false
                            print("Successfully decoded \(response.transcriptions.count) segments")
                        } else {
                            print("Failed to decode response from: \(text)")
                        }
                    case .data:
                        print("Received unexpected data message")
                    @unknown default:
                        break
                    }
                    self?.receiveMessages()
                    
                case .failure(let error):
                    print("WebSocket Error: \(error.localizedDescription)")
                    self?.error = "WebSocket Error: \(error.localizedDescription)"
                    self?.isConnected = false
                    self?.isProcessing = false
                }
            }
        }
    }
    
    func toggleRecording() {
        if audioRecorder.isRecording {
            if let audioURL = audioRecorder.stopRecording() {
                sendRecording(url: audioURL)
            }
        } else {
            do {
                try audioRecorder.startRecording()
            } catch {
                self.error = "Recording Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func sendRecording(url: URL) {
        isProcessing = true
        
        Task {
            do {
                let metadata: [String: String] = [
                    "file_name": "recording.wav",
                    "mime_type": "audio/wav"
                ]
                let metadataString = String(data: try JSONEncoder().encode(metadata), encoding: .utf8)!
                try await webSocketTask?.send(.string(metadataString))
                
                let audioData = try Data(contentsOf: url)
                let chunkSize = 1024
                var offset = 0
                
                while offset < audioData.count {
                    let chunk = audioData[offset..<min(offset + chunkSize, audioData.count)]
                    try await webSocketTask?.send(.data(Data(chunk)))
                    offset += chunkSize
                }
                
                try await webSocketTask?.send(.data(Data()))
                
            } catch {
                await MainActor.run {
                    self.error = "WebSocket Send Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
}

// MARK: - Main View
struct AGIView: View {
    @StateObject var viewModel: AGIViewModel
    
    init(serverURL: String) {
        _viewModel = StateObject(wrappedValue: AGIViewModel(serverURL: serverURL))
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isConnected ? "Server Connected" : "Connection Lost - Please Wait")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        Button(action: viewModel.toggleRecording) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.isRecording ? Color.red : Color.blue)
                                    .frame(width: 80, height: 80)
                                
                                if viewModel.isProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                } else {
                                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(viewModel.isProcessing)
                        
                        if viewModel.isProcessing {
                            Text("Processing audio...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if viewModel.isRecording {
                            Text("Recording in progress...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if viewModel.segments.isEmpty && !viewModel.isProcessing && !viewModel.isRecording {
                            Text("Start recording to see transcription")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.segments) { segment in
                                    SegmentView(segment: segment)
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding()
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") {}
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
}

struct SegmentView: View {
    let segment: AGISegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(segment.speaker)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.1f - %.1f", segment.timestamp.start, segment.timestamp.end))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(segment.transcription)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    
    // Helper function to format speaker label
    private func formatSpeakerLabel(_ speaker: String) -> String {
        return speaker.isEmpty ? "Speaker" : speaker
    }
    
    // Helper function to format timestamp
    private func formatTimestamp(start: Double, end: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return "\(formatter.string(from: NSNumber(value: start)) ?? "0.0")s - \(formatter.string(from: NSNumber(value: end)) ?? "0.0")s"
    }
}
