//
//  MainContentView.swift
//  mahdi
//
//  Created by Elijah Arbee on 11/22/24.
//

import SwiftUI

struct MainContentView: View {
    @StateObject private var audioService = AudioService()
    
    var body: some View {
        VStack {
            // Live Header
            LiveHeaderView(
                isRecording: $audioService.isRecording,
                uploadStatus: audioService.uploadStatus,
                toggleRecording: toggleRecording
            )
            .padding(.top)
            
            // Live Transcription Section
            LiveTranscriptionView(transcriptions: audioService.liveTranscriptions)
                .padding(.horizontal)
                .padding(.top, 5)
            
            Divider()
                .padding(.vertical)
            
            // Historical Transcription Section
            HistoricalTranscriptionsView(transcriptions: audioService.historicalTranscriptions)
                .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(.systemGray6))
    }
    
    // Toggle Recording State
    private func toggleRecording() {
        if audioService.isRecording {
            audioService.stopRecording()
        } else {
            audioService.startRecording()
        }
    }
}

// MARK: - LiveHeaderView

struct LiveHeaderView: View {
    @Binding var isRecording: Bool
    var uploadStatus: String
    var toggleRecording: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Live Transcription")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text("Status: \(uploadStatus)")
                    .font(.subheadline)
                    .foregroundColor(isRecording ? .red : .green)
                
                Spacer()
                
                Button(action: toggleRecording) {
                    HStack {
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(isRecording ? .red : .green)
                        Text(isRecording ? "Stop" : "Start")
                            .foregroundColor(.primary)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// MARK: - LiveTranscriptionView

struct LiveTranscriptionView: View {
    var transcriptions: [AudioResult]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Ongoing Transcriptions")
                .font(.headline)
                .padding(.bottom, 5)
            
            if transcriptions.isEmpty {
                Text("No live transcriptions available.")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(transcriptions) { transcription in
                            TranscriptionCardView(transcription: transcription)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
}

// MARK: - HistoricalTranscriptionsView

struct HistoricalTranscriptionsView: View {
    var transcriptions: [AudioResult]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Historical Transcriptions")
                .font(.headline)
                .padding(.bottom, 5)
            
            if transcriptions.isEmpty {
                Text("No historical transcriptions available.")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(transcriptions) { transcription in
                            TranscriptionCardView(transcription: transcription)
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
    }
}

// MARK: - TranscriptionCardView

struct TranscriptionCardView: View {
    var transcription: AudioResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(transcription.file)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text(transcription.status.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor(status: transcription.status))
            }
            
            Text(transcription.data.transcription)
                .font(.body)
                .foregroundColor(.primary)
            
            // Additional Details
            VStack(alignment: .leading, spacing: 4) {
                Text("Clarity: \(transcription.data.clarity)")
                Text("Emotional Undertones: \(transcription.data.emotional_undertones)")
                Text("Environment Context: \(transcription.data.environment_context)")
                Text("Pronunciation Accuracy: \(transcription.data.pronunciation_accuracy)")
                Text("Speech Patterns: Pace - \(transcription.data.speech_patterns.pace), Tone - \(transcription.data.speech_patterns.tone), Volume - \(transcription.data.speech_patterns.volume)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func statusColor(status: String) -> Color {
        switch status.lowercased() {
        case "processed":
            return .green
        case "processing":
            return .orange
        default:
            return .gray
        }
    }
}
