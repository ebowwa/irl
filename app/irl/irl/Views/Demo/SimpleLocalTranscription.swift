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

    @State private var transcriptionHistory: [String] = []
    @State private var lastTranscribedText: String = ""

    var body: some View {
        VStack(spacing: 16) {
            TranscriptionHeaderView()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    TranscriptionHistoryView(transcriptionHistory: transcriptionHistory, lastTranscribedText: lastTranscribedText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)

            if !speechManager.isBackgroundNoiseReady {
                CalibrationStatusView()
            } else {
                AudioLevelView(audioLevel: $speechManager.currentAudioLevel)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            setupSpeechManager()
        }
        .onDisappear {
            speechManager.stopRecording()
        }
    }

    private func setupSpeechManager() {
        speechManager.requestSpeechAuthorization()
        speechManager.startRecording()

        speechManager.$transcribedText
            .dropFirst()
            .sink { newTranscription in
                handleTranscriptionUpdate(newTranscription)
            }
            .store(in: &speechManager.cancellables)
    }

    private func handleTranscriptionUpdate(_ newTranscription: String) {
        if newTranscription != lastTranscribedText && !newTranscription.isEmpty {
            lastTranscribedText = newTranscription
        } else if newTranscription == lastTranscribedText {
            transcriptionHistory.append(lastTranscribedText)
            lastTranscribedText = ""
        }
    }
}


//
//  TranscriptionHistoryView.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import SwiftUI

struct TranscriptionHistoryView: View {
    let transcriptionHistory: [String]
    let lastTranscribedText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(transcriptionHistory, id: \.self) { sentence in
                MessageBubble(text: sentence)
            }

            if !lastTranscribedText.isEmpty {
                GradientTextView(text: lastTranscribedText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

//
//  TranscriptionHeaderView.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import SwiftUI

struct TranscriptionHeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Speak")
                .font(.title)
                .fontWeight(.bold)
            Text("Voice transcription is active")
                .foregroundColor(.secondary)
        }
    }
}


//
//  MessageBubble.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import SwiftUI

struct MessageBubble: View {
    let text: String

    var body: some View {
        HStack {
            Text(text)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(CustomBubbleShape())
        }
        .padding(.trailing, 60)
    }
}


//
//  CustomBubbleShape.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import SwiftUI

struct CustomBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: 20, height: 20)
        )
        return Path(path.cgPath)
    }
}

//
//  CalibrationStatusView.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import SwiftUI

struct CalibrationStatusView: View {
    var body: some View {
        VStack(spacing: 8) {
            ProgressView("Calibrating ambient noise levels...")
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
            Text("Please wait while we measure your environment...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
