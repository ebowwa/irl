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
import ReSwift
#if os(iOS)
import UIKit
#endif
import GoogleSignIn

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
                                         by: stride).map { channelDataValue[$0] }
        let squares = channelDataValueArray.map { $0 * $0 }
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

struct HomeView: View {
    @EnvironmentObject var appStateObservable: AppStateObservable
    @StateObject private var audioRecorder = AudioRecorder()
    
    var body: some View {
        NavigationView {
            VStack {
                if appStateObservable.state.audio.isRecording {
                    RecordingView(isRecording: $appStateObservable.state.audio.isRecording)
                } else {
                    RecordingListView(recordings: appStateObservable.state.audio.recordings)
                }
                
                Spacer()
                
                RecordButton(isRecording: appStateObservable.state.audio.isRecording) {
                    handleRecordTap()
                }
            }
            .navigationTitle("Recordings")
            .navigationBarItems(trailing: settingsButton)
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            appStateObservable.dispatch(.navigation(.navigate(.settings)))
        }) {
            Image(systemName: "gear")
                .foregroundColor(.primary)
        }
    }
    
    private func handleRecordTap() {
        if appStateObservable.state.audio.isRecording {
            if let url = audioRecorder.stopRecording() {
                appStateObservable.dispatch(.audio(.recordingSuccess(url)))
            }
        } else {
            do {
                try audioRecorder.startRecording()
                appStateObservable.dispatch(.audio(.startRecording))
            } catch {
                appStateObservable.dispatch(.audio(.recordingError(error)))
            }
        }
    }
}

// MARK: - Recording View
struct RecordingView: View {
    @Binding var isRecording: Bool
    
    var body: some View {
        VStack {
            Text("Recording...")
                .font(.title)
                .foregroundColor(.red)
            
            // Add visualization here if desired
        }
    }
}

// MARK: - Recording List View
struct RecordingListView: View {
    let recordings: [Recording]
    
    var body: some View {
        List {
            ForEach(recordings) { recording in
                RecordingCell(recording: recording)
            }
        }
    }
}

// MARK: - Recording Cell
struct RecordingCell: View {
    let recording: Recording
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(recording.title)
                    .font(.headline)
                Text(recording.timestamp.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatDuration(recording.duration))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
}

// MARK: - Record Button
struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 80, height: 80)
                
                if isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 66, height: 66)
                }
            }
        }
        .padding(.bottom, 32)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppStateObservable())
}
