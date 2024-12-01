//
//  HomeView.swift
//  CaringMind
//
//  Created by Elijah Arbee on 11/10/24.
//
//  Updated to communicate with the new HTTP-based backend for real-time transcription.
//
//  Enhancements:
//  1. Aggregates per-word server segments into sentences for cleaner UI display.
//  2. Ensures multiple uploads are handled correctly, appending to existing segments.
//  3. Adds comprehensive logging for debugging purposes.
//

import SwiftUI
import Speech
import AVFoundation
#if os(iOS)
import UIKit
#endif

// MARK: - Models

/// Represents the start and end times of a speech segment.
struct AGITimestamp: Codable {
    let start: Double
    let end: Double
}

/// Represents a segment of transcribed audio with metadata.
struct AGISegment: Codable, Identifiable {
    let id: UUID
    let timestamp: AGITimestamp
    let speaker: String
    let transcription: String
    
    init(timestamp: AGITimestamp, speaker: String, transcription: String) {
        self.id = UUID()
        self.timestamp = timestamp
        self.speaker = speaker
        self.transcription = transcription
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case speaker
        case transcription
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(AGITimestamp.self, forKey: .timestamp)
        speaker = try container.decode(String.self, forKey: .speaker)
        transcription = try container.decode(String.self, forKey: .transcription)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(speaker, forKey: .speaker)
        try container.encode(transcription, forKey: .transcription)
    }
}

/// Represents a single entry in the transcript with relevant metadata.
struct TranscriptEntry: Codable, Identifiable {
    let id: UUID
    let text: String
    let timestamp: Date
    let startTime: TimeInterval
    let endTime: TimeInterval
    let confidence: Float
    let sequenceNumber: Int
    
    init(text: String, timestamp: Date, startTime: TimeInterval, endTime: TimeInterval, confidence: Float, sequenceNumber: Int) {
        self.id = UUID()
        self.text = text
        self.timestamp = timestamp
        self.startTime = startTime
        self.endTime = endTime
        self.confidence = confidence
        self.sequenceNumber = sequenceNumber
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        endTime = try container.decode(TimeInterval.self, forKey: .endTime)
        confidence = try container.decode(Float.self, forKey: .confidence)
        sequenceNumber = try container.decode(Int.self, forKey: .sequenceNumber)
    }
    
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

// MARK: - FlexibleDouble Struct

/// A flexible decoder to handle values that might be either String or Double.
struct FlexibleDouble: Codable {
    let value: Double
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self),
                  let doubleVal = Double(stringVal) {
            value = doubleVal
        } else {
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double or String convertible to Double"))
        }
    }
}

// MARK: - AudioRecorder Class

class AudioRecorder: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFile: AVAudioFile?
    private var converter: AVAudioConverter?
    private let desiredSampleRate: Double = 16000.0
    private let desiredChannels: AVAudioChannelCount = 1
    private var audioLevelNode: AVAudioMixerNode?
    
    @Published var isRecording = false
    @Published var audioLevel: Double = 0.0
    @Published var error: String?
    @Published var url: URL?
    
    override init() {
        super.init()
        #if os(iOS)
        configureAudioSession()
        #endif
        setupAudioEngine()
        setupAudioLevelMonitoring()
        #if os(iOS)
        setupInterruptionHandling()
        #endif
    }
    
    #if os(iOS)
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Failed to configure audio session: \(error.localizedDescription)"
        }
    }
    
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleInterruption),
                                             name: AVAudioSession.interruptionNotification,
                                             object: nil)
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            stopRecording()
        } else if type == .ended {
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    try? startRecording()
                }
            }
        }
    }
    #endif
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        audioLevelNode = AVAudioMixerNode()
        
        guard let audioEngine = audioEngine,
              let inputNode = inputNode,
              let audioLevelNode = audioLevelNode else {
            error = "Failed to initialize audio components"
            return
        }
        
        audioEngine.attach(audioLevelNode)
        audioEngine.connect(inputNode, to: audioLevelNode, format: inputNode.outputFormat(forBus: 0))
        
        let format = AVAudioFormat(standardFormatWithSampleRate: desiredSampleRate, channels: desiredChannels)
        audioEngine.connect(audioLevelNode, to: audioEngine.mainMixerNode, format: format)
    }
    
    private func setupAudioLevelMonitoring() {
        audioLevelNode?.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            guard let self = self else { return }
            let level = buffer.rms
            DispatchQueue.main.async {
                self.audioLevel = level
            }
        }
    }
    
    func startRecording() throws {
        #if os(iOS)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }
            if granted {
                self.beginRecording()
            } else {
                self.error = "Microphone access denied"
            }
        }
        #else
        beginRecording()
        #endif
    }
    
    private func beginRecording() {
        guard let audioEngine = audioEngine else {
            error = "Audio engine not initialized"
            return
        }
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            self.error = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() -> URL? {
        audioEngine?.stop()
        isRecording = false
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = "Error deactivating audio session: \(error.localizedDescription)"
        }
        #endif
        
        // Create a URL for the recorded audio file
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let audioURL = documentDirectory.appendingPathComponent("recorded_audio.oga")
        
        // Set the URL for the recorded audio file
        url = audioURL
        
        return audioURL
    }
}

extension AVAudioPCMBuffer {
    var rms: Double {
        guard let channelData = self.floatChannelData else { return 0 }
        let channelDataValue = channelData.pointee
        let stride = 1
        let channelDataValueArray = Swift.stride(from: 0,
                                         to: Int(self.frameLength),
                                         by: stride).map{ channelDataValue[$0] }
        let squares = channelDataValueArray.map{ $0 * $0 }
        let sum = squares.reduce(0, +)
        let mean = sum / Float(channelDataValueArray.count)
        return sqrt(Double(mean))
    }
}

// MARK: - TranscriptionManager Class

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
    
    /// Requests necessary permissions for speech recognition and microphone access.
    private func requestPermissions() {
        #if os(iOS)
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized.")
                case .denied, .restricted, .notDetermined:
                    self?.errorMessage = "Speech recognition authorization denied."
                    print("Speech recognition authorization denied.")
                @unknown default:
                    self?.errorMessage = "Unknown authorization status."
                    print("Unknown speech recognition authorization status.")
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.errorMessage = "Microphone access denied."
                    print("Microphone access denied.")
                }
            }
        }
        #endif
    }
    
    /// Starts the transcription process.
    func startTranscription() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer not available."
            print("Speech recognizer not available.")
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
                print("Transcription task ended.")
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
            print("Audio engine couldn't start: \(error.localizedDescription)")
        }
    }
    
    /// Processes the transcription result.
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
                        createTranscriptEntry(for: sentence, startTime: currentSentenceStartTime, endTime: previousEndTime, confidence: 0.0, sequenceNumber: sequenceCounter)
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
    
    /// Creates a transcript entry from the recognized sentence.
    private func createTranscriptEntry(for sentence: String, startTime: TimeInterval, endTime: TimeInterval, confidence: Float, sequenceNumber: Int) {
        sequenceCounter += 1
        
        let entry = TranscriptEntry(
            text: sentence,
            timestamp: Date(),
            startTime: startTime,
            endTime: endTime,
            confidence: confidence,
            sequenceNumber: sequenceCounter
        )
        
        DispatchQueue.main.async {
            self.transcriptEntries.append(entry)
            print("New sentence detected (#\(self.sequenceCounter)): \(sentence)")
        }
    }
    
    /// Stops the transcription process.
    func stopTranscription() {
        if audioEngine != nil {
            audioEngine.stop()
            inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
            print("Transcription stopped.")
        }
    }
}

// MARK: - AGIViewModel Class

/// Handles HTTP communication, integrates audio recording and transcription.
@MainActor
class AGIViewModel: ObservableObject {
    @Published var transcription = ""
    @Published var transcriptEntries: [TranscriptEntry] = []
    @Published var isProcessing = false
    @Published var error: String?
    @Published var segments: [AGISegment] = []
    @Published var audioLevel: Double = 0.0
    
    private let audioRecorder = AudioRecorder()
    private let transcriptionManager = TranscriptionManager()
    private let session = URLSession.shared
    
    init() {
        bindAudioLevel()
        bindTranscriptionManager()
    }
    
    /// Binds the audio level from the AudioRecorder to the ViewModel.
    private func bindAudioLevel() {
        audioRecorder.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)
    }
    
    /// Binds the transcription results from the TranscriptionManager to the ViewModel.
    private func bindTranscriptionManager() {
        transcriptionManager.$transcribedText
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcription)
        
        transcriptionManager.$transcriptEntries
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcriptEntries)
    }
    
    /// Toggles the recording state and handles the upload process.
    func toggleRecording() {
        if audioRecorder.isRecording {
            if let url = audioRecorder.stopRecording() {
                transcriptionManager.stopTranscription()
                uploadRecording(url: url)
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
    
    /// Uploads the recorded audio file to the server via HTTP POST.
    private func uploadRecording(url: URL) {
        isProcessing = true
        
        // Prepare the URL without the batch parameter for real-time processing
        guard let uploadURL = URL(string: "https://8bdb-2a09-bac5-661b-1232-00-1d0-c6.ngrok-free.app/onboarding/v6/process-audio?prompt_type=transcription") else {
            self.error = "Invalid server URL."
            self.isProcessing = false
            return
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        // Generate a unique boundary string using a UUID
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Construct the multipart form data
        let mimeType = "audio/ogg" // Adjust based on your audio format
        let fileName = url.lastPathComponent
        let fieldName = "files" // Ensure this matches the server's expected field name
        
        var body = Data()
        
        // Add the audio file to the form data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        if let fileData = try? Data(contentsOf: url) {
            body.append(fileData)
        } else {
            self.error = "Failed to read audio file."
            self.isProcessing = false
            return
        }
        body.append("\r\n")
        
        // Close the multipart form data
        body.append("--\(boundary)--\r\n")
        
        // Set the request body
        request.httpBody = body
        
        // Create the upload task
        let uploadTask = session.dataTask(with: request) { [weak self] data, response, error in
            let workItem = DispatchWorkItem {
                guard let self = self else { return }
                
                if let error = error {
                    print("Error uploading audio: \(error)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Upload status code: \(httpResponse.statusCode)")
                }
                
                if let data = data {
                    Task { @MainActor in
                        do {
                            let decoder = JSONDecoder()
                            let response = try decoder.decode(AGIViewModel.ServerResponse.self, from: data)
                            
                            if let segments = response.results.first?.data?.segments {
                                let groupedSegments = await self.groupSegments(segments)
                                
                                let mappedSegments = groupedSegments.map { group -> AGISegment in
                                    let start = group.first?.start_time.value ?? 0
                                    let end = group.last?.end_time.value ?? 0
                                    let speaker = group.first?.speaker_id ?? "Unknown"
                                    let combinedTranscription = group.map { $0.transcription_text }.joined(separator: " ")
                                    
                                    return AGISegment(
                                        timestamp: AGITimestamp(start: start, end: end),
                                        speaker: speaker,
                                        transcription: combinedTranscription
                                    )
                                }
                                
                                self.segments.append(contentsOf: mappedSegments)
                                print("Mapped \(mappedSegments.count) grouped segments.")
                            } else {
                                print("No segments found in server response.")
                                self.error = "No segments received from server."
                            }
                            
                            self.isProcessing = false
                            try? FileManager.default.removeItem(at: url)
                            print("Audio file deleted after successful upload.")
                        } catch {
                            self.error = "Failed to decode server response: \(error.localizedDescription)"
                            print("Decoding error: \(error.localizedDescription)")
                            self.isProcessing = false
                        }
                    }
                }
            }
            DispatchQueue.main.async(execute: workItem)
        }
        
        // Start the upload task
        uploadTask.resume()
    }
    
    /// Groups consecutive segments into sentences based on speaker continuity and minimal time gaps.
    private func groupSegments(_ segments: [ServerResponse.Result.DataClass.Segment]) async -> [[ServerResponse.Result.DataClass.Segment]] {
        guard !segments.isEmpty else { return [] }
        var groupedSegments: [[ServerResponse.Result.DataClass.Segment]] = [[segments[0]]]
        
        for segment in segments.dropFirst() {
            if let lastGroup = groupedSegments.last,
               let lastSegment = lastGroup.last,
               lastSegment.speaker_id == segment.speaker_id,
               segment.start_time.value - lastSegment.end_time.value < 1.0 { // 1 second gap threshold
                groupedSegments[groupedSegments.count - 1].append(segment)
            } else {
                groupedSegments.append([segment])
            }
        }
        return groupedSegments
    }
    
    /// Cancels all ongoing upload tasks when the ViewModel is deinitialized.
    deinit {
        print("AGIViewModel deinitialized.")
    }
    
    /// Represents the server's JSON response structure.
    struct ServerResponse: Codable {
        struct Result: Codable {
            struct DataClass: Codable {
                struct Segment: Codable, Identifiable {
                    let id = UUID()
                    let start_time: FlexibleDouble
                    let end_time: FlexibleDouble
                    let sequence_id: Int
                    let speaker_id: String
                    let transcription_text: String
                    
                    private enum CodingKeys: String, CodingKey {
                        case start_time, end_time, sequence_id, speaker_id, transcription_text
                    }
                }
                let segments: [Segment]?
            }
            let files: [String]?
            let status: String
            let data: DataClass?
        }
        let results: [Result]
    }
}

// MARK: - AGIView

struct AGIView: View {
    @StateObject private var viewModel = AGIViewModel()
    @StateObject private var audioRecorder = AudioRecorder()
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack {
            if authManager.isSignedIn {
                VStack(spacing: 20) {
                    Text("Welcome \(authManager.userName ?? "User")")
                        .font(.title)
                        .padding()
                    
                    // Recording status and visualization
                    HStack {
                        Circle()
                            .fill(audioRecorder.isRecording ? Color.red : Color.gray)
                            .frame(width: 12, height: 12)
                        Text(audioRecorder.isRecording ? "Recording..." : "Ready")
                            .foregroundColor(audioRecorder.isRecording ? .red : .primary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    
                    // Audio level visualization
                    AudioLevelView(level: audioRecorder.audioLevel)
                        .frame(height: 60)
                        .padding(.horizontal)
                    
                    // Transcript list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.transcriptEntries) { entry in
                                TranscriptEntryView(entry: entry)
                                    .transition(.opacity)
                            }
                        }
                        .padding()
                    }
                    
                    // Record button
                    Button(action: {
                        if audioRecorder.isRecording {
                            _ = audioRecorder.stopRecording()
                        } else {
                            do {
                                try audioRecorder.startRecording()
                            } catch {
                                print("Error starting recording: \(error)")
                            }
                        }
                    }) {
                        Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(audioRecorder.isRecording ? .red : .blue)
                        #if os(iOS)
                        if #available(iOS 17.0, *) {
                            symbolEffect(.bounce, value: audioRecorder.isRecording)
                        }
                        #endif
                    }
                    .padding()
                }
            } else {
                Text("Please sign in to use the app")
                    .font(.title)
                    .padding()
            }
        }
        .navigationTitle("mahdi")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .alert("Error", isPresented: .constant(viewModel.error != nil || audioRecorder.error != nil)) {
            Button("OK") {
                viewModel.error = nil
                audioRecorder.error = nil
            }
        } message: {
            if let error = viewModel.error ?? audioRecorder.error {
                Text(error)
            }
        }
    }
    
    private func saveTranscription(_ text: String) {
        if authManager.userID != nil {
            print("Saving transcription: \(text)")
        }
    }
}

struct AudioLevelView: View {
    let level: Double
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<Int(geometry.size.width / 6), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index, total: Int(geometry.size.width / 6)))
                        .frame(width: 4, height: barHeight(for: index, total: Int(geometry.size.width / 6)))
                }
            }
        }
    }
    
    private func barHeight(for index: Int, total: Int) -> CGFloat {
        let progress = Double(index) / Double(total)
        let amplitude = sin(progress * .pi) * level
        return max(4, amplitude * 60)
    }
    
    private func barColor(for index: Int, total: Int) -> Color {
        let progress = Double(index) / Double(total)
        return Color.blue.opacity(progress * level)
    }
}

struct TranscriptEntryView: View {
    let entry: TranscriptEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.text)
                .font(.body)
            
            HStack {
                Text(entry.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(String(format: "%.1fs", entry.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Data Extension for Multipart Form Data

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - Preview

struct AGIView_Previews: PreviewProvider {
    static var previews: some View {
        AGIView()
    }
}
