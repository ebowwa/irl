/**
//  TranscriptionView.swift
//   CaringMind
//
//  Created by Elijah Arbee on 11/9/24.
//
import SwiftUI


// Then update only the view portion while keeping everything else the same
struct TranscriptionView: View {
    @StateObject private var transcriptionManager = TranscriptionManager()
    @Environment(\.colorScheme) var colorScheme
    @State private var lastContentOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Audio Level Visualization
                AudioLevelView(level: transcriptionManager.audioLevel)

                // Live Transcription Text
                if !transcriptionManager.transcribedText.isEmpty {
                    Text(transcriptionManager.transcribedText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // Segmented Transcript Display
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(transcriptionManager.transcriptEntries) { entry in
                                TranscriptEntryCard(entry: entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onChange(of: transcriptionManager.transcriptEntries.count) { _ in
                        if let lastId = transcriptionManager.transcriptEntries.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Controls
                HStack(spacing: 30) {
                    // Record Button
                    Button(action: {
                        if transcriptionManager.isRecording {
                            transcriptionManager.stopRecording()
                        } else {
                            transcriptionManager.startRecording()
                        }
                    }) {
                        Circle()
                            .fill(transcriptionManager.isRecording ? .red : .blue)
                            .frame(width: 64, height: 64)
                            .overlay {
                                Image(systemName: transcriptionManager.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            .shadow(radius: 5)
                    }

                    if transcriptionManager.isRecording {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Recording")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: {
                        transcriptionManager.clearTranscription()
                    }) {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("Live Transcription")
            .overlay {
                if transcriptionManager.isCalibrating {
                    CalibrationView()
                }
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { transcriptionManager.errorMessage != nil },
                set: { if !$0 { transcriptionManager.errorMessage = nil } }
            )) {
                Button("OK") {
                    transcriptionManager.errorMessage = nil
                }
            } message: {
                Text(transcriptionManager.errorMessage ?? "")
            }
        }
    }
}

struct TranscriptEntryCard: View {
    let entry: TranscriptEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.text)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            HStack {
                Text(entry.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(String(format: "%.1fs", entry.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
}

// Existing AudioLevelView remains the same
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
        .frame(height: 8)
        .padding(.horizontal)
    }
}

// Existing CalibrationView remains the same
struct CalibrationView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Calibrating microphone...")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Please remain quiet for a moment")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(40)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.6))
                    .blur(radius: 0.5)
            }
        }
    }
}
*/
