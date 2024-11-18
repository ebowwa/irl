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
import AVFoundation
import Speech
import NaturalLanguage

// MARK: - Models

/// Represents the start and end times of a speech segment.
struct AGITimestamp: Codable {
    let start: Double
    let end: Double
}

/// Represents a segment of transcribed audio with metadata.
struct AGISegment: Codable, Identifiable {
    let id = UUID()
    let timestamp: AGITimestamp
    let speaker: String
    let transcription: String
}

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
    
    /// Configures the audio session.
    private func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setPreferredSampleRate(desiredSampleRate)
            try audioSession.setPreferredInputNumberOfChannels(Int(desiredChannels))
            try audioSession.setActive(true)
            print("Audio session configured successfully.")
        } catch {
            print("Error configuring AVAudioSession: \(error.localizedDescription)")
        }
    }
    
    /// Sets up the audio engine for recording.
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
        
        print("Audio engine set up successfully.")
    }
    
    /// Sets up audio level monitoring for visualization.
    private func setupAudioLevelMonitoring() {
        audioLevelNode = AVAudioMixerNode()
        guard let mixerNode = audioLevelNode else { return }
        
        audioEngine.attach(mixerNode)
        let inputFormat = inputNode.outputFormat(forBus: 0)
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioLevel(buffer: buffer)
        }
        
        print("Audio level monitoring set up successfully.")
    }
    
    /// Processes the audio buffer to determine audio level.
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
    
    /// Updates the audio level during recording if needed.
    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        // Placeholder for any additional audio level updates
    }
    
    /// Converts and writes the audio buffer to the file.
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
    
    /// Writes the audio buffer directly to the file.
    private func writeBuffer(buffer: AVAudioPCMBuffer, audioFile: AVAudioFile) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try audioFile.write(from: buffer)
            } catch {
                print("Error writing buffer: \(error.localizedDescription)")
            }
        }
    }
    
    /// Starts recording audio.
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
    
    /// Stops recording audio and returns the file URL.
    func stopRecording() -> URL? {
        guard let audioFile = audioFile else { return nil }
        
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isRecording = false
        print("Recording stopped.")
        
        return audioFile.url
    }
    
    /// Sets up handling for audio session interruptions.
    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        print("Interruption handling set up successfully.")
    }
    
    /// Handles audio session interruptions.
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            if isRecording {
                _ = stopRecording()
                print("Recording stopped due to interruption.")
            }
        } else if type == .ended {
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("Audio session reactivated after interruption.")
            } catch {
                print("Error reactivating AVAudioSession: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        audioLevelNode?.removeTap(onBus: 0)
        print("AudioRecorder deinitialized.")
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
    
    /// Creates a transcript entry from the recognized sentence.
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
    @Published var audioLevel: Double = 0.0 // For audio level visualization
    
    let audioRecorder = AudioRecorder()
    let transcriptionManager = TranscriptionManager()
    
    private var uploadTasks: [URL: URLSessionDataTask] = [:]
    
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
            if let audioURL = audioRecorder.stopRecording() {
                transcriptionManager.stopTranscription()
                uploadRecording(url: audioURL)
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
        let session = URLSession.shared
        let uploadTask = session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.error = "Upload failed: \(error.localizedDescription)"
                    print("Upload error: \(error.localizedDescription)")
                    self.isProcessing = false
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.error = "Invalid server response."
                    print("Invalid server response.")
                    self.isProcessing = false
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Attempt to parse server-provided error message
                    if let data = data,
                       let serverError = String(data: data, encoding: .utf8) {
                        self.error = "Server error (\(httpResponse.statusCode)): \(serverError)"
                        print("Server error (\(httpResponse.statusCode)): \(serverError)")
                    } else {
                        self.error = "Server error: \(httpResponse.statusCode)"
                        print("Server error: \(httpResponse.statusCode)")
                    }
                    self.isProcessing = false
                    return
                }
                
                guard let data = data else {
                    self.error = "No data received from server."
                    print("No data received from server.")
                    self.isProcessing = false
                    return
                }
                
                // Log the raw server response
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Server Response: \(responseString)")
                }
                
                do {
                    let serverResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
                    
                    // Handle both single and multiple results
                    if let firstResult = serverResponse.results.first,
                       let serverSegments = firstResult.data?.segments {
                        print("Received \(serverSegments.count) segments from server.")
                        
                        // Group segments into sentences
                        let groupedSegments = self.groupSegments(serverSegments)
                        
                        // Map grouped segments to AGISegment
                        let mappedSegments = groupedSegments.map { group -> AGISegment in
                            guard let first = group.first, let last = group.last else {
                                // This should never happen, but handle gracefully
                                let defaultTimestamp = AGITimestamp(start: 0.0, end: 0.0)
                                return AGISegment(timestamp: defaultTimestamp, speaker: "Speaker", transcription: "Invalid segment")
                            }
                            
                            let startTime = first.start_time.value
                            let endTime = last.end_time.value
                            
                            // Combine transcription texts
                            let combinedTranscription = group.map { $0.transcription_text }.joined(separator: " ")
                            
                            let timestamp = AGITimestamp(start: startTime, end: endTime)
                            
                            // Assuming all segments in a group have the same speaker
                            let speaker = group.first?.speaker_id ?? "Speaker"
                            
                            return AGISegment(timestamp: timestamp,
                                              speaker: speaker,
                                              transcription: combinedTranscription)
                        }
                        self.segments.append(contentsOf: mappedSegments)
                        print("Mapped \(mappedSegments.count) grouped segments.")
                    } else {
                        print("No segments found in server response.")
                        self.error = "No segments received from server."
                    }
                    
                    self.isProcessing = false
                    // Delete the audio file after successful upload
                    try? FileManager.default.removeItem(at: url)
                    print("Audio file deleted after successful upload.")
                } catch {
                    self.error = "Failed to decode server response: \(error.localizedDescription)"
                    print("Decoding error: \(error.localizedDescription)")
                    self.isProcessing = false
                }
            }
        }
        
        // Start the upload task
        uploadTask.resume()
        
        // Keep track of the upload task if needed for cancellation
        uploadTasks[url] = uploadTask
    }
    
    /// Groups consecutive segments into sentences based on speaker continuity and minimal time gaps.
    private func groupSegments(_ segments: [ServerResponse.Result.DataClass.Segment]) -> [[ServerResponse.Result.DataClass.Segment]] {
        guard !segments.isEmpty else { return [] }
        
        var groupedSegments: [[ServerResponse.Result.DataClass.Segment]] = []
        var currentGroup: [ServerResponse.Result.DataClass.Segment] = [segments[0]]
        
        for i in 1..<segments.count {
            let previous = segments[i - 1]
            let current = segments[i]
            
            let timeGap = current.start_time.value - previous.end_time.value
            let sameSpeaker = current.speaker_id == previous.speaker_id
            
            print("Time gap between segment \(i-1) and \(i): \(timeGap), Same speaker: \(sameSpeaker)")
            
            if timeGap < 1.0 && sameSpeaker { // Adjust the time gap threshold as needed
                currentGroup.append(current)
            } else {
                groupedSegments.append(currentGroup)
                currentGroup = [current]
            }
        }
        
        // Append the last group
        groupedSegments.append(currentGroup)
        
        print("Grouped into \(groupedSegments.count) segments.")
        return groupedSegments
    }
    
    /// Cancels all ongoing upload tasks when the ViewModel is deinitialized.
    deinit {
        for (_, task) in uploadTasks {
            task.cancel()
        }
        print("AGIViewModel deinitialized and all upload tasks canceled.")
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

/// Main SwiftUI view that provides the user interface.
struct AGIView: View {
    @StateObject var viewModel: AGIViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: AGIViewModel())
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Processing Status
                HStack {
                    if viewModel.isProcessing {
                        ProgressView("Processing...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Audio Level Visualization
                AudioLevelView(level: viewModel.audioLevel)
                    .frame(height: 8)
                    .padding(.horizontal)
                
                // Live Transcription
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
                
                // Server Transcriptions
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
                
                // Controls
                HStack(spacing: 30) {
                    Button(action: viewModel.toggleRecording) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isProcessing ? Color.gray : (viewModel.audioRecorder.isRecording ? Color.red : Color.blue))
                                .frame(width: 64, height: 64)
                            
                            if viewModel.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            } else {
                                Image(systemName: viewModel.audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(viewModel.isProcessing)
                    
                    if viewModel.audioRecorder.isRecording {
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
    
    /// Formats the speaker label.
    private func formatSpeakerLabel(_ speaker: String) -> String {
        return speaker.isEmpty ? "Speaker" : speaker
    }
    
    /// Formats the timestamp display.
    private func formatTimestamp(start: Double, end: Double) -> String {
        return String(format: "%.1f - %.1f s", start, end)
    }
}

// MARK: - AudioLevelView

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
