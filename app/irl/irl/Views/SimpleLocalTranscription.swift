//
//  SimpleLocalTranscription.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
//

import Foundation
import Speech
import Combine

class SimpleLocalTranscriptionViewModel: ObservableObject {
    @Published var transcriptionHistory: [String] = []
    @Published var lastTranscribedText: String = ""
    @Published var currentAudioLevel: Double = 0.0
    @Published var isBackgroundNoiseReady: Bool = false

    // Use singleton instances
    private let speechManager = SpeechRecognitionManager.shared
    private let soundManager = SoundMeasurementManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupManagers()
    }

    func startRecording() {
        speechManager.startRecording()
    }

    func stopRecording() {
        speechManager.stopRecording()
    }

    private func setupManagers() {
        // Request authorization and start recording
        speechManager.requestSpeechAuthorization()
        speechManager.startRecording()

        // Subscribe to transcribed text updates
        speechManager.$transcribedText
            .dropFirst()
            .sink { [weak self] newTranscription in
                self?.handleTranscriptionUpdate(newTranscription)
            }
            .store(in: &cancellables)

        // Subscribe to audio level updates from SoundMeasurementManager
        soundManager.$currentAudioLevel
            .sink { [weak self] level in
                self?.currentAudioLevel = level
            }
            .store(in: &cancellables)

        // Subscribe to background noise readiness from SoundMeasurementManager
        soundManager.$isBackgroundNoiseReady
            .sink { [weak self] isReady in
                self?.isBackgroundNoiseReady = isReady
            }
            .store(in: &cancellables)
    }

    private func handleTranscriptionUpdate(_ newTranscription: String) {
        if newTranscription != lastTranscribedText && !newTranscription.isEmpty {
            lastTranscribedText = newTranscription
        } else if newTranscription == lastTranscribedText && !lastTranscribedText.isEmpty {
            transcriptionHistory.append(lastTranscribedText)
            lastTranscribedText = ""
        }
    }
}


//
//  SimpleLocalTranscriptionView.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import SwiftUI

struct SimpleLocalTranscription: View {
    @StateObject private var viewModel = SimpleLocalTranscriptionViewModel()

    var body: some View {
        VStack(spacing: 16) {
            TranscriptionHeaderView()

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    TranscriptionHistoryView(
                        transcriptionHistory: viewModel.transcriptionHistory,
                        lastTranscribedText: viewModel.lastTranscribedText
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)

            if !viewModel.isBackgroundNoiseReady {
                CalibrationStatusView()
            } else {
                AudioLevelView(audioLevel: .constant(viewModel.currentAudioLevel))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            viewModel.startRecording()
        }
        .onDisappear {
            viewModel.stopRecording()
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

//
//  AudioLevelView.swift
//  IRL
//
//  Created by Elijah Arbee on 10/11/24.
//
import SwiftUI

struct AudioLevelView: View {
    @Binding var audioLevel: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("Audio Level")
                .font(.headline)
            ProgressView(value: audioLevel, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 10)
        }
        .padding()
    }
}
