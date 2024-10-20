/**
//  AudioStreamView.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
import SwiftUI
import Combine

struct AudioStreamView: View {
    @EnvironmentObject var audioState: AudioController
    @StateObject private var whisperService = WhisperService()
    @State private var transcription: String = ""
    @State private var selectedLanguage: AppLanguage?
    
    let languageManager = LanguageManager.shared
    
    var body: some View {
        VStack {
            Text("Audio Stream")
                .font(.title)
                .padding()
            
            if audioState.isRecording {
                Text("Recording in progress...")
                    .foregroundColor(.green)
            } else {
                Text("Recording stopped")
                    .foregroundColor(.red)
            }
            
            Text(audioState.formattedRecordingTime)
                .font(.headline)
                .padding()
            
            Button(action: audioState.toggleRecording) {
                Text(audioState.isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .background(audioState.isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            if audioState.isPlaybackAvailable {
                Button(action: audioState.togglePlayback) {
                    Text(audioState.isPlaying ? "Pause Playback" : "Play Recording")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            Picker("Language", selection: $selectedLanguage) {
                ForEach(languageManager.getWhisperSupportedLanguages(), id: \.self) { language in
                    Text(language.name).tag(Optional(language))
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            
            if !transcription.isEmpty {
                Text("Transcription:")
                    .font(.headline)
                    .padding(.top)
                
                ScrollView {
                    Text(transcription)
                        .padding()
                }
            }
            
            if whisperService.isLoading {
                ProgressView("Transcribing...")
            }
        }
        .onAppear {
            selectedLanguage = languageManager.language(forCode: "en")
        }
        .onReceive(audioState.$currentRecording) { newRecording in
            if let recording = newRecording {
                transcribeAudio(url: recording.url)
            }
        }
        .onReceive(audioState.$errorMessage) { errorMessage in
            if let error = errorMessage {
                print("Audio Error: \(error)")
                // You might want to display this error to the user
            }
        }
    }
    
    private func transcribeAudio(url: URL) {
        guard let language = selectedLanguage else {
            print("No language selected")
            return
        }
        
        whisperService.uploadFile(url: url, task: .transcribe, language: language)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Transcription error: \(error)")
                }
            }, receiveValue: { _ in
                // The transcription is updated through the @Published property in WhisperService
            })
            .store(in: &whisperService.cancellables)
        
        // Subscribe to changes in the WhisperService output
        whisperService.$output
            .receive(on: DispatchQueue.main)
            .sink { output in
                self.transcription = output.text
            }
            .store(in: &whisperService.cancellables)
    }
}
*/
