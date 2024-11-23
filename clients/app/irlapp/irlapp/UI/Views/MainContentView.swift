//
//  MainContentView.swift
//  mahdi
//
//  Created by Elijah Arbee on 11/22/24.
//

import SwiftUI
import UIKit

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
        .onReceive(audioService.$liveTranscriptions) { transcriptions in
            // Log the media file URLs whenever live transcriptions are updated
            for transcription in transcriptions {
                for uri in transcription.file_uris {
                    print("Media File URL: \(uri)")
                }
            }
        }
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
            
            // Safely access 'transcription' field
            if let transcriptionText = transcription.data["transcription"]?.value as? String {
                Text(transcriptionText)
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                Text("No transcription available.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            // Additional Details
            VStack(alignment: .leading, spacing: 4) {
                if let clarity = transcription.data["clarity"]?.value as? String {
                    Text("Clarity: \(clarity)")
                }
                
                if let emotionalUndertones = transcription.data["emotional_undertones"]?.value as? String {
                    Text("Emotional Undertones: \(emotionalUndertones)")
                }
                
                if let environmentContext = transcription.data["environment_context"]?.value as? String {
                    Text("Environment Context: \(environmentContext)")
                }
                
                if let pronunciationAccuracy = transcription.data["pronunciation_accuracy"]?.value as? String {
                    Text("Pronunciation Accuracy: \(pronunciationAccuracy)")
                }
                
                // Handling nested 'speech_patterns' dictionary
                if let speechPatterns = transcription.data["speech_patterns"]?.value as? [String: Any] {
                    let pace = speechPatterns["pace"] as? String ?? "N/A"
                    let tone = speechPatterns["tone"] as? String ?? "N/A"
                    let volume = speechPatterns["volume"] as? String ?? "N/A"
                    Text("Speech Patterns: Pace - \(pace), Tone - \(tone), Volume - \(volume)")
                }
                
                // Display Media File URLs
                // NOTE: this is for debugging and not likely to make the final cut in this capacity.. maybe as a developer mode in another presentation look
                // NOTE: These audio files url should be saved sequentially to local db
                // - the audio can then be reused as we can pass it the 
                if !transcription.file_uris.isEmpty {
                    Text("Media Files:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(transcription.file_uris, id: \.self) { uri in
                        Text(uri)
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .underline()
                            .onTapGesture {
                                openURL(uri)
                            }
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Helper Methods
    
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
    
    /// Opens the given URL string in the default web browser.
    /// - Parameter urlString: The URL string to open.
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return
        }
        UIApplication.shared.open(url)
    }
}
