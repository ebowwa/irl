//
//  MainContentView.swift
//  mahdi
//
//  Created by Elijah Arbee on 11/22/24.
//
// TODO: (LATER) polling should be replaced with local transcription, when final results are outputted then we should send the relevant audio data, and in dialogue we can continue feeding the original audio files to the model
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI

// MARK: - Models

struct ConversationAnalysis: Codable, Identifiable {
    let id = UUID()
    let speaker: String
    let text: String
    let toneAnalysis: ToneAnalysis
    let confidence: Double
    let summary: String
    let redFlags: [RedFlag]?

    enum CodingKeys: String, CodingKey {
        case speaker
        case text
        case toneAnalysis = "tone_analysis"
        case confidence
        case summary
        case redFlags = "red_flags"
    }
}

struct ToneAnalysis: Codable {
    let tone: String
    let indicators: [String]
}

struct RedFlag: Codable, Identifiable {
    var id: UUID
    let description: String
    let evidence: [String]

    init(id: UUID = UUID(), description: String, evidence: [String]) {
        self.id = id
        self.description = description
        self.evidence = evidence
    }
}

// MARK: - Views

struct MainContentView: View {
    @StateObject private var audioService = AudioService()

    var body: some View {
        VStack {
            LiveHeaderView(
                isRecording: $audioService.isRecording,
                uploadStatus: audioService.uploadStatus
            )
            .padding(.top)

            LiveTranscriptionView(transcriptions: audioService.liveTranscriptions)
                .padding(.horizontal)
                .padding(.top, 5)

            Divider()
                .padding(.vertical)

            HistoricalTranscriptionsView(transcriptions: audioService.historicalTranscriptions)
                .padding(.horizontal)

            Spacer()
        }
        .background(Group {
            #if os(iOS)
            Color(uiColor: .systemGray6)
            #else
            Color.gray.opacity(0.1)
            #endif
        })
    }
}

struct LiveHeaderView: View {
    @Binding var isRecording: Bool
    let uploadStatus: String

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

                Image(systemName: isRecording ? "mic.fill" : "mic.slash.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isRecording ? .red : .gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct HistoricalTranscriptionsView: View {
    let transcriptions: [AudioResult]

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
                    LazyVStack(alignment: .leading, spacing: 10) {
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

struct TranscriptionCardView: View {
    let transcription: AudioResult

    private func decodeConversationAnalysis() -> [ConversationAnalysis] {
        guard let analysisData = transcription.data["conversation_analysis"]?.value as? [[String: Any]] else {
            return []
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: analysisData)
            let decoder = JSONDecoder()
            return try decoder.decode([ConversationAnalysis].self, from: jsonData)
        } catch {
            print("Error decoding conversation analysis: \(error)")
            return []
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(transcription.file)  // No need for optionals since we made it non-optional in the model
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Text(transcription.status.capitalized)  // No need for optionals
                    .font(.caption)
                    .foregroundColor(statusColor(status: transcription.status))
            }

            VStack(alignment: .leading) {
                if let transcriptionText = transcription.data["transcription"]?.value as? String {
                    Text(transcriptionText)
                        .font(.body)
                }

                let conversationAnalysis = decodeConversationAnalysis()
                if !conversationAnalysis.isEmpty {
                    ForEach(conversationAnalysis) { analysis in
                        AnalysisContentView(analysis: analysis)
                    }
                }
            }

            if let fileURI = URL(string: transcription.file_uri) {
                Link("View Recording", destination: fileURI)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Group {
            #if os(iOS)
            Color(uiColor: .systemGray5)
            #else
            Color.gray.opacity(0.2)
            #endif
        })
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func statusColor(status: String) -> Color {
        switch status.lowercased() {
        case "processed": return .green
        case "processing": return .orange
        default: return .gray
        }
    }
}

struct LiveTranscriptionView: View {
    let transcriptions: [AudioResult]

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
                    LazyVStack(alignment: .leading, spacing: 10) {
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

struct AnalysisContentView: View {
    let analysis: ConversationAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Speaker: \(analysis.speaker)")
                .font(.headline)

            Text(analysis.text)
                .font(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text("Tone: \(analysis.toneAnalysis.tone)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Indicators: \(analysis.toneAnalysis.indicators.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(String(format: "Confidence: %.1f%%", analysis.confidence))
                .font(.caption)

            Text("Summary: \(analysis.summary)")
                .font(.body)

            if let redFlags = analysis.redFlags, !redFlags.isEmpty {
                RedFlagsView(redFlags: redFlags)
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal)
        .background(Group {
            #if os(iOS)
            Color(uiColor: .systemGray5)
            #else
            Color.gray.opacity(0.2)
            #endif
        })
        .cornerRadius(8)
    }
}

struct RedFlagsView: View {
    let redFlags: [RedFlag]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Red Flags:")
                .font(.subheadline)
                .fontWeight(.semibold)
            ForEach(redFlags) { flag in
                VStack(alignment: .leading, spacing: 1) {
                    Text("• \(flag.description)")
                        .font(.caption)
                    Text("Evidence: \(flag.evidence.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 2)
    }
}

#Preview {
    MainContentView()
}
