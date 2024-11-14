//
//  HomeView.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/10/24.
//
//  Main AppView
//  [LOGIC] Redirect user here upon sign-in. This view handles local transcriptions and segments audio by sentences and speakers.
//  - Local transcriptions: Used for real-time processing; connects to backend WebSocket expecting audio segments in configurable durations.
//  - Audio format: Record in WAV, optimized for clear, natural sound quality.
//  - [INSTRUCTION] Implement sequentially numbered processing steps for clarity and structure.
//
//  Audio files should auto-delete after uploading to `genai_media_upload_route` to manage storage efficiently.
//  - Route URL: `/v2/upload-to-gemini`
//  - Base server: `https://2157-2601-646-a201-db60-00-2386.ngrok-free.app`
//  Note: Consider Google’s media storage capabilities for revisiting audio with additional queries or tasks.
//
//  File Naming:
//  - Avoid generic names like `recording.wav`, as multiple uploads will occur.
//  - Implement a unique naming convention before forwarding to GoogleGenAI to ensure distinguishable file identities.
//
// issue: multiple requests can be made, but for some reason only one will go through and return a response..
// TODO:
// - delete after good response back not before
// - the local transcription isnt occuring
// - websocket might be very unnecessary - should just be uploads to gemini upload then webhooks stream in output, i.e. post initiates webhook
// i like how it currently counts how many segments, maybe we can use this and save the segments alongside the audio in the server
import SwiftUI
import AVFoundation
import Speech
import NaturalLanguage

// MARK: - Models

/// 1. **AGITimestamp Struct**
/// Represents the start and end times of a speech segment.
struct AGITimestamp: Codable {
    let start: Double
    let end: Double
}

/// 2. **AGISegment Struct**
/// Represents a segment of transcribed audio with metadata.
struct AGISegment: Codable, Identifiable {
    let id = UUID()
    let timestamp: AGITimestamp
    let speaker: String
    let transcription: String
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, speaker, transcription
    }
}

/// 3. **TranscriptEntry Model**
/// Represents a single entry in the transcript with relevant metadata.
struct TranscriptEntry: Identifiable, Codable {
    let id = UUID()
    let text: String
    let timestamp: Date
    let startTime: TimeInterval
    let endTime: TimeInterval
    let sequenceNumber: Int
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    var duration: TimeInterval {
        return endTime - startTime
    }
}

// MARK: - AudioRecorder Class

/// 4. **AudioRecorder Class**
/// Manages audio recording, ensuring correct format and handling interruptions.
class AudioRecorder: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    private var audioFile: AVAudioFile?
    private var converter: AVAudioConverter?
    private let desiredSampleRate: Double = 16000.0 // Adjust as per server requirements
    private let desiredChannels: AVAudioChannelCount = 1 // Mono recording
    private var audioLevelNode: AVAudioMixerNode?
    
    @Published var isRecording = false
    @Published var audioLevel: Double = 0.0 // For audio level visualization
    
    override init() {
        super.init()
        configureAudioSession()
        setupAudioEngine()
        setupAudioLevelMonitoring()
        setupInterruptionHandling()
    }
    
    /// 4.1 **Configure Audio Session**
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setPreferredSampleRate(desiredSampleRate)
            try audioSession.setPreferredInputNumberOfChannels(Int(desiredChannels))
            try audioSession.setActive(true)
        } catch {
            print("Error configuring AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    /// 4.2 **Setup Audio Engine**
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
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
        
        inputNode.installTap(onBus: 0, bufferSize: 512, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self, let audioFile = self.audioFile else { return }
            
            self.updateAudioLevel(buffer: buffer)
            
            if let converter = self.converter {
                let desiredFormat = converter.outputFormat
                self.convertAndWrite(buffer: buffer, converter: converter, audioFile: audioFile, desiredFormat: desiredFormat)
            } else {
                self.writeBuffer(buffer: buffer, audioFile: audioFile)
            }
        }
    }
    
    /// 4.3 **Setup Audio Level Monitoring**
    private func setupAudioLevelMonitoring() {
        audioLevelNode = AVAudioMixerNode()
        guard let mixerNode = audioLevelNode else { return }
        
        audioEngine.attach(mixerNode)
        let inputFormat = inputNode.outputFormat(forBus: 0)
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioLevel(buffer: buffer)
        }
    }
    
    /// 4.4 **Process Audio Level**
    private func processAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelCount = Int(buffer.format.channelCount)
        let length = Int(buffer.frameLength)
        
        var maxAmplitude: Float = 0.0
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<length {
                maxAmplitude = max(maxAmplitude, abs(data[frame]))
            }
        }
        
        let db = 20 * log10(maxAmplitude)
        let normalizedValue = (db + 60) / 60
        
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = Double(max(0, min(1, normalizedValue)))
        }
    }
    
    /// 4.5 **Update Audio Level**
    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        // This function can be used to update audio level during recording if needed
    }
    
    /// 4.6 **Convert and Write Buffer**
    private func convertAndWrite(buffer: AVAudioPCMBuffer, converter: AVAudioConverter, audioFile: AVAudioFile, desiredFormat: AVAudioFormat) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let convertedBuffer = AVAudioPCMBuffer(
                pcmFormat: desiredFormat,
                frameCapacity: AVAudioFrameCount(desiredFormat.sampleRate * Double(buffer.frameLength) / buffer.format.sampleRate)
            ) else {
                print("Failed to create converted buffer.")
                return
            }
    
            var error: NSError?
            var hasProvidedInput = false // Track if input has been provided
    
            let status = converter.convert(to: convertedBuffer, error: &error, withInputFrom: { inNumPackets, outStatus in
                if hasProvidedInput {
                    outStatus.pointee = .noDataNow
                    return nil
                } else {
                    hasProvidedInput = true
                    outStatus.pointee = .haveData
                    return buffer
                }
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
    }
    
    /// 4.7 **Write Buffer**
    private func writeBuffer(buffer: AVAudioPCMBuffer, audioFile: AVAudioFile) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try audioFile.write(from: buffer)
            } catch {
                print("Error writing buffer: \(error.localizedDescription)")
            }
        }
    }
    
    /// 4.8 **Start Recording**
    func startRecording() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let uniqueFileName = "recording_\(UUID().uuidString).wav"
        let audioFilename = documentsPath.appendingPathComponent(uniqueFileName)
        
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
    
    /// 4.9 **Stop Recording**
    func stopRecording() -> URL? {
        guard let audioFile = audioFile else { return nil }
        
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isRecording = false
        print("Recording stopped.")
        
        return audioFile.url
    }
    
    /// 4.10 **Setup Interruption Handling**
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    /// 4.11 **Handle Interruption**
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            if isRecording {
                _ = stopRecording()
            }
        } else if type == .ended {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Error reactivating AVAudioSession: \(error.localizedDescription)")
            }
        }
    }
    
    /// 4.12 **Deinitializer**
    deinit {
        NotificationCenter.default.removeObserver(self)
        audioLevelNode?.removeTap(onBus: 0)
    }
}

// MARK: - TranscriptionManager Class

/// 5. **TranscriptionManager Class**
/// Manages speech recognition and processes transcribed text.
class TranscriptionManager: NSObject, ObservableObject {
    @Published var transcribedText: String = ""
    @Published var transcriptEntries: [TranscriptEntry] = []
    @Published var errorMessage: String?
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine!
    private var inputNode: AVAudioInputNode!
    
    private var lastProcessedSegmentIndex: Int = 0
    private var currentSentenceStartTime: TimeInterval = 0
    private var bufferText: String = ""
    private let silenceThreshold: TimeInterval = 0.8
    private var sequenceCounter: Int = 0
    private var lastEndTime: TimeInterval = 0
    
    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        requestPermissions()
    }
    
    /// 5.1 **Request Permissions**
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized.")
                case .denied, .restricted, .notDetermined:
                    self?.errorMessage = "Speech recognition authorization denied."
                @unknown default:
                    self?.errorMessage = "Unknown authorization status."
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.errorMessage = "Microphone access denied."
                }
            }
        }
    }
    
    /// 5.2 **Start Transcription**
    func startTranscription() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer not available."
            return
        }
        
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.processTranscription(result)
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                self.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        do {
            try audioEngine.start()
            print("Transcription started.")
        } catch {
            errorMessage = "Audio engine couldn't start."
        }
    }
    
    /// 5.3 **Process Transcription**
    private func processTranscription(_ result: SFSpeechRecognitionResult) {
        let transcription = result.bestTranscription
        let segments = transcription.segments
        
        guard lastProcessedSegmentIndex < segments.count else { return }
        
        for i in lastProcessedSegmentIndex..<segments.count {
            let segment = segments[i]
            let word = segment.substring
            let timestamp = segment.timestamp
            let duration = segment.duration
            
            bufferText += word + " "
            
            if i > 0 {
                let previousSegment = segments[i - 1]
                let previousEndTime = previousSegment.timestamp + previousSegment.duration
                let pauseDuration = timestamp - previousEndTime
                
                if pauseDuration > silenceThreshold {
                    let sentence = bufferText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !sentence.isEmpty {
                        createTranscriptEntry(for: sentence, startTime: currentSentenceStartTime, endTime: previousEndTime)
                    }
                    bufferText = ""
                    currentSentenceStartTime = timestamp
                    lastEndTime = previousEndTime
                }
            } else {
                if currentSentenceStartTime == 0 {
                    currentSentenceStartTime = timestamp
                }
            }
            
            lastEndTime = timestamp + duration
        }
        
        transcribedText = transcription.formattedString
        lastProcessedSegmentIndex = segments.count
    }
    
    /// 5.4 **Create Transcript Entry**
    private func createTranscriptEntry(for sentence: String, startTime: TimeInterval, endTime: TimeInterval) {
        sequenceCounter += 1
        
        let entry = TranscriptEntry(
            text: sentence,
            timestamp: Date(),
            startTime: startTime,
            endTime: endTime,
            sequenceNumber: sequenceCounter
        )
        
        DispatchQueue.main.async {
            self.transcriptEntries.append(entry)
            print("New sentence detected (#\(self.sequenceCounter)): \(sentence)")
        }
    }
    
    /// 5.5 **Stop Transcription**
    func stopTranscription() {
        if audioEngine != nil {
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
            print("Transcription stopped.")
        }
    }
}

// MARK: - TranscriptionResponse Struct

/// 6. **TranscriptionResponse Struct**
/// Represents the server's response containing transcription segments.
struct TranscriptionResponse: Codable {
    let status: String
    let transcriptions: [AGISegment]
}

// MARK: - AGIViewModel Class

/// 7. **AGIViewModel Class**
/// Handles WebSocket communication and integrates audio recording and transcription.
@MainActor
class AGIViewModel: ObservableObject {
    @Published var transcription = ""
    @Published var transcriptEntries: [TranscriptEntry] = []
    @Published var isConnected = false
    @Published var isProcessing = false
    @Published var error: String?
    @Published var segments: [AGISegment] = []
    @Published var audioLevel: Double = 0.0 // For audio level visualization
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let serverURL: String
    private let audioRecorder = AudioRecorder()
    private let transcriptionManager = TranscriptionManager()
    
    var isRecording: Bool { audioRecorder.isRecording }
    
    init(serverURL: String) {
        self.serverURL = serverURL
        setupWebSocket()
        bindAudioLevel()
        bindTranscriptionManager()
    }
    
    /// 7.1 **Bind Audio Level**
    private func bindAudioLevel() {
        audioRecorder.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)
    }
    
    /// 7.2 **Bind Transcription Manager**
    private func bindTranscriptionManager() {
        transcriptionManager.$transcribedText
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcription)
        
        transcriptionManager.$transcriptEntries
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcriptEntries)
    }
    
    /// 7.3 **Setup WebSocket**
    private func setupWebSocket() {
        guard let url = URL(string: serverURL) else {
            error = "Invalid WebSocket URL."
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        print("WebSocket connected.")
        receiveMessages()
    }
    
    /// 7.4 **Receive Messages**
    private func receiveMessages() {
        guard let webSocketTask = webSocketTask else { return }
        
        webSocketTask.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }
                
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("Received WebSocket message: \(text)")
                        if let data = text.data(using: .utf8) {
                            do {
                                let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
                                self.segments = response.transcriptions
                                self.isProcessing = false
                                print("Successfully decoded \(response.transcriptions.count) segments")
                            } catch {
                                print("Decoding error: \(error.localizedDescription)")
                                print("Failed to decode response from: \(text)")
                            }
                        } else {
                            print("Failed to convert text to data")
                        }
                    case .data(let data):
                        print("Received data message")
                        // Handle binary data if needed
                    @unknown default:
                        print("Unknown message type received.")
                    }
                    self.receiveMessages() // Continue receiving messages
                    
                case .failure(let error):
                    print("WebSocket Error: \(error.localizedDescription)")
                    self.error = "WebSocket Error: \(error.localizedDescription)"
                    self.isConnected = false
                    self.isProcessing = false
                }
            }
        }
    }
    
    /// 7.5 **Toggle Recording**
    func toggleRecording() {
        if audioRecorder.isRecording {
            if let audioURL = audioRecorder.stopRecording() {
                transcriptionManager.stopTranscription()
                sendRecording(url: audioURL)
            }
        } else {
            do {
                try audioRecorder.startRecording()
                transcriptionManager.startTranscription()
            } catch {
                self.error = "Recording Error: \(error.localizedDescription)"
            }
        }
    }
    
    /// 7.6 **Send Recording**
    private func sendRecording(url: URL) {
        isProcessing = true
        
        Task {
            do {
                let uniqueFileName = url.lastPathComponent
                let metadata: [String: String] = [
                    "file_name": uniqueFileName,
                    "mime_type": "audio/wav"
                ]
                let metadataData = try JSONEncoder().encode(metadata)
                let metadataString = String(data: metadataData, encoding: .utf8)!
                try await webSocketTask?.send(.string(metadataString))
                print("Sent metadata to server: \(metadataString)")
                
                let audioData = try Data(contentsOf: url)
                let chunkSize = 1024
                var offset = 0
                
                while offset < audioData.count {
                    let chunk = audioData[offset..<min(offset + chunkSize, audioData.count)]
                    try await webSocketTask?.send(.data(Data(chunk)))
                    offset += chunkSize
                }
                
                try await webSocketTask?.send(.data(Data())) // Indicate end of data
                print("Sent audio data to server.")
                
                // Delete the audio file after uploading
                try FileManager.default.removeItem(at: url)
                print("Audio file deleted after upload.")
                
            } catch {
                await MainActor.run {
                    self.error = "WebSocket Send Error: \(error.localizedDescription)"
                    self.isProcessing = false
                }
                print("Error sending recording: \(error.localizedDescription)")
            }
        }
    }
    
    /// 7.7 **Disconnect WebSocket**
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        print("WebSocket disconnected.")
    }
}

// MARK: - AGIView

/// 8. **AGIView**
/// Main SwiftUI view that provides the user interface.
struct AGIView: View {
    @StateObject var viewModel: AGIViewModel
    
    init(serverURL: String) {
        _viewModel = StateObject(wrappedValue: AGIViewModel(serverURL: serverURL))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 8.1 **Connection Status**
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
                
                // 8.2 **Audio Level Visualization**
                AudioLevelView(level: viewModel.audioLevel)
                    .frame(height: 8)
                    .padding(.horizontal)
                
                // 8.3 **Live Transcription**
                if !viewModel.transcriptEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Transcription")
                            .font(.headline)
                        ScrollView {
                            ForEach(viewModel.transcriptEntries) { entry in
                                Text(entry.text)
                                    .padding(4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                    .padding()
                }
                
                // 8.4 **Server Transcriptions**
                if !viewModel.segments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Server Transcriptions")
                            .font(.headline)
                        ScrollView {
                            ForEach(viewModel.segments) { segment in
                                SegmentView(segment: segment)
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                    .padding()
                }
                
                Spacer()
                
                // 8.5 **Controls**
                HStack(spacing: 30) {
                    Button(action: viewModel.toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isRecording ? Color.red : Color.blue)
                                .frame(width: 64, height: 64)
                            
                            if viewModel.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            } else {
                                Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(viewModel.isProcessing)
                    
                    if viewModel.isRecording {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Recording")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Live Transcription")
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
}

// MARK: - SegmentView

/// 9. **SegmentView**
/// Displays individual segments of transcribed audio.
struct SegmentView: View {
    let segment: AGISegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatSpeakerLabel(segment.speaker))
                    .font(.headline)
                Spacer()
                Text(formatTimestamp(start: segment.timestamp.start, end: segment.timestamp.end))
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
    
    private func formatSpeakerLabel(_ speaker: String) -> String {
        return speaker.isEmpty ? "Speaker" : speaker
    }
    
    private func formatTimestamp(start: Double, end: Double) -> String {
        return String(format: "%.1f - %.1f s", start, end)
    }
}

// MARK: - AudioLevelView

/// 10. **AudioLevelView**
/// Visualizes the current audio level.
struct AudioLevelView: View {
    let level: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .green, .yellow, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * level, height: 8)
                    .animation(.linear(duration: 0.1), value: level)
            }
        }
    }
}
