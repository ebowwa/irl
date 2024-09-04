//
//  SpeechDemo.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import SwiftUI
import Speech

class SpeechRecognitionManager: ObservableObject {
    @Published var transcribedText = "This is where the transcribed text will appear."
    @Published var isRecording = false
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                if authStatus != .authorized {
                    self?.transcribedText = "Speech recognition not authorized"
                }
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
                self.transcribedText = "Listening..."
            }
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}

struct SpeechDemo: View {
    @StateObject private var speechManager = SpeechRecognitionManager()
    
    var body: some View {
        VStack(spacing: 32) {
            Button(action: {
                if speechManager.isRecording {
                    speechManager.stopRecording()
                } else {
                    speechManager.startRecording()
                }
            }) {
                Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 128, height: 128)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(spacing: 8) {
                Text("Speak")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Tap the button to start voice transcription")
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Transcription Output")
                    .font(.headline)
                Text(speechManager.transcribedText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            speechManager.requestSpeechAuthorization()
        }
    }
}
