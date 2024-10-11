//
//  SimpleLocalTranscription.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//

import SwiftUI
import Speech
import Combine

struct SimpleLocalTranscription: View {
    @StateObject private var speechManager = SpeechRecognitionManager()
    @ObservedObject private var audioState = AudioState.shared

    var body: some View {
        VStack(spacing: 32) {
            // Removed the recording button as audio is always recording
            
            VStack(spacing: 8) {
                Text("Speak")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Voice transcription is active")
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Transcription Output")
                    .font(.headline)
                ScrollView {
                    Text(speechManager.transcribedText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
            
            // Optional: Display audio levels from AudioState
            VStack(spacing: 8) {
                Text("Audio Level")
                    .font(.headline)
                ProgressView(value: speechManager.currentAudioLevel, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 10)
            }
            .padding()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            speechManager.requestSpeechAuthorization()
            speechManager.startRecording()
        }
        .onReceive(audioState.audioLevelPublisher) { level in
            let normalizedLevel = self.normalizeAudioLevel(level)
            self.speechManager.currentAudioLevel = normalizedLevel
        }
        .onDisappear {
            speechManager.stopRecording()
        }
    }
    
    /// Normalizes the audio level from decibels to a value between 0 and 1.
    private func normalizeAudioLevel(_ level: Float) -> Double {
        let minDb: Float = -80.0
        let maxDb: Float = 0.0
        let clampedLevel = max(min(level, maxDb), minDb)
        return Double((clampedLevel - minDb) / (maxDb - minDb))
    }
}

import SwiftUI
import Speech
import Combine

class SpeechRecognitionManager: ObservableObject {
    @Published var transcribedText = "Transcribed text will appear here."
    @Published var transcriptionSegments: [String] = [] // New property for bubbles
    @Published var currentAudioLevel: Double = 0.0
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // To keep track of processed segments
    private var lastProcessedIndex: Int = 0
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    break // Authorized
                case .denied, .restricted, .notDetermined:
                    self?.transcribedText = "Speech recognition not authorized."
                @unknown default:
                    self?.transcribedText = "Unknown authorization status."
                }
            }
        }
    }
    
    func startRecording() {
        guard !audioEngine.isRunning else { return }
        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Configure the audio session for recording and playback
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            transcribedText = "Failed to set up audio session: \(error.localizedDescription)"
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create SFSpeechAudioBufferRecognitionRequest.")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Start the recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                    self.updateTranscriptionSegments(from: result.bestTranscription)
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    // Optionally handle UI updates on stop
                }
            }
        }
        
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        
        // Install a tap on the audio engine's input node to capture audio data
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.transcribedText = "Listening..."
            }
        } catch {
            transcribedText = "Audio Engine couldn't start: \(error.localizedDescription)"
        }
        
        //  Audio levels monitored using Combine and AudioState's audioLevelPublisher

        // This part is optional and depends on how you want to display audio levels
    }
    
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
    }
    
    private func updateTranscriptionSegments(from transcription: SFTranscription) {
        // Ensure that we process only new segments
        let newSegments = transcription.segments.dropFirst(lastProcessedIndex)
        for segment in newSegments {
            let start = transcription.formattedString.index(transcription.formattedString.startIndex, offsetBy: segment.substringRange.location)
            let end = transcription.formattedString.index(start, offsetBy: segment.substringRange.length)
            let substring = String(transcription.formattedString[start..<end])
            transcriptionSegments.append(substring)
        }
        lastProcessedIndex = transcription.segments.count
    }
}

struct SimpleLocalTranscription_Previews: PreviewProvider {
    static var previews: some View {
        SimpleLocalTranscription()
    }
}
