//
//  HomeView.swift
//  irlapp
//
//  Created by Elijah Arbee on 11/2/24.
//
// TranscriptionManager.swift
import Foundation
import Speech
import AVFoundation

class TranscriptionManager: NSObject, ObservableObject {
    @Published var transcriptionHistory: [TranscriptionEntry] = []
    @Published var currentTranscription: String = ""
    @Published var audioLevel: Double = 0.0
    @Published var isRecording: Bool = false
    @Published var isCalibrating: Bool = true
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioLevelTimer: Timer?
    private var baselineAudioLevel: Double = 0.0
    private var audioLevelNode: AVAudioMixerNode?
    
    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        setupAudioSession()
        setupAudioLevelMonitoring()
        checkPermissions()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
        }
    }
    
    private func setupAudioLevelMonitoring() {
        // Create a mixer node for level monitoring
        audioLevelNode = AVAudioMixerNode()
        if let mixerNode = audioLevelNode {
            audioEngine.attach(mixerNode)
            
            // Connect input to mixer
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
            
            // Install tap on mixer node
            mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
                self?.processTapBuffer(buffer)
            }
        }
    }
    
    private func processTapBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelCount = Int(buffer.format.channelCount)
        let length = Int(buffer.frameLength)
        
        var maxAmplitude: Float = 0.0
        
        // Process all channels
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<length {
                let absolute = abs(data[frame])
                maxAmplitude = max(maxAmplitude, absolute)
            }
        }
        
        // Convert to decibels
        let db = 20 * log10(maxAmplitude)
        // Normalize to 0-1 range (-60db to 0db)
        let normalizedValue = (db + 60) / 60
        
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = Double(max(0, min(1, normalizedValue)))
        }
    }
    
    private func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                if status == .authorized {
                    self?.startCalibration()
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            if !granted {
                DispatchQueue.main.async {
                    self?.errorMessage = "Microphone access is required for transcription"
                }
            }
        }
    }
    
    func startCalibration() {
        isCalibrating = true
        var samples: [Double] = []
        
        // Start audio engine for calibration
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            return
        }
        
        // Collect samples for 3 seconds
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            samples.append(self.audioLevel)
            
            if samples.count >= 30 { // 3 seconds
                timer.invalidate()
                self.baselineAudioLevel = samples.reduce(0, +) / Double(samples.count)
                self.isCalibrating = false
                // Stop engine temporarily
                self.audioEngine.stop()
                // Start actual recording
                self.startRecording()
            }
        }
    }
    
    func startRecording() {
        guard !isRecording,
              let recognizer = speechRecognizer,
              recognizer.isAvailable else {
            errorMessage = "Speech recognition is not available"
            return
        }
        
        do {
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.taskHint = .dictation
            
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            // Only install tap for speech recognition
            inputNode.installTap(onBus: 0,
                               bufferSize: 1024,
                               format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }
            
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    
                    DispatchQueue.main.async {
                        self.currentTranscription = transcribedText
                        
                        if result.isFinal {
                            let entry = TranscriptionEntry(
                                text: transcribedText,
                                timestamp: Date(),
                                confidence: result.bestTranscription.segments.map { $0.confidence }.reduce(0, +) / Float(result.bestTranscription.segments.count)
                            )
                            self.transcriptionHistory.append(entry)
                            self.currentTranscription = ""
                        }
                    }
                }
                
                if error != nil {
                    self.stopRecording()
                }
            }
            
            isRecording = true
            
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        // Remove speech recognition tap
        audioEngine.inputNode.removeTap(onBus: 0)
        
        // Stop recognition tasks
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        // Stop audio engine
        audioEngine.stop()
        isRecording = false
    }
    
    deinit {
        stopRecording()
        audioLevelNode?.removeTap(onBus: 0)
    }
}

// TranscriptionEntry.swift
struct TranscriptionEntry: Identifiable, Codable {
    let id: UUID = UUID()
    let text: String
    let timestamp: Date
    let confidence: Float
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

// TranscriptionView.swift
import SwiftUI

struct TranscriptionView: View {
    @StateObject private var transcriptionManager = TranscriptionManager()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerSection
                
                if transcriptionManager.isCalibrating {
                    CalibrationView()
                } else {
                    transcriptionContent
                }
            }
            .padding()
            .navigationTitle("Voice Transcription")
            .alert("Error", isPresented: .constant(transcriptionManager.errorMessage != nil)) {
                Button("OK") {
                    transcriptionManager.errorMessage = nil
                }
            } message: {
                Text(transcriptionManager.errorMessage ?? "")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            StatusIndicator(isRecording: transcriptionManager.isRecording)
            AudioLevelIndicator(level: transcriptionManager.audioLevel)
        }
    }
    
    private var transcriptionContent: some View {
        VStack(spacing: 16) {
            transcriptionHistory
            currentTranscriptionView
            controlButtons
        }
    }
    
    private var transcriptionHistory: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(transcriptionManager.transcriptionHistory) { entry in
                        TranscriptionBubble(entry: entry)
                            .id(entry.id)
                    }
                }
                .onChange(of: transcriptionManager.transcriptionHistory.count) { _ in
                    if let lastId = transcriptionManager.transcriptionHistory.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
    }
    
    private var currentTranscriptionView: some View {
        Text(transcriptionManager.currentTranscription)
            .italic()
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(colorScheme == .dark ? Color.black.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                if transcriptionManager.isRecording {
                    transcriptionManager.stopRecording()
                } else {
                    transcriptionManager.startRecording()
                }
            }) {
                Label(
                    transcriptionManager.isRecording ? "Stop" : "Start",
                    systemImage: transcriptionManager.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                )
                .font(.title2)
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: {
                transcriptionManager.transcriptionHistory.removeAll()
            }) {
                Label("Clear", systemImage: "trash")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }
}

// Supporting Views
struct StatusIndicator: View {
    let isRecording: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isRecording ? Color.red : Color.gray)
                .frame(width: 12, height: 12)
            Text(isRecording ? "Recording" : "Idle")
                .foregroundColor(isRecording ? .primary : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AudioLevelIndicator: View {
    let level: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .green, .yellow, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * level)
            }
        }
        .frame(height: 8)
        .cornerRadius(4)
    }
}

struct TranscriptionBubble: View {
    let entry: TranscriptionEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.text)
                .padding()
                .background(colorScheme == .dark ? Color.blue.opacity(0.3) : Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            HStack {
                Text(entry.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Confidence: \(Int(entry.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
        }
    }
}

struct CalibrationView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Calibrating microphone...")
                .font(.headline)
            
            Text("Please remain quiet for a moment")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// Preview Provider
struct TranscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptionView()
    }
}
