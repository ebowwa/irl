//
//  AudioRecorderDebugMenuView.swift
//  irl
//
//  Created by Elijah Arbee on 8/30/24.
//
// lets not immediately begin recording with viewing of the page

import SwiftUI
import Combine

@available(iOS 17.0, *)
struct AudioRecorderDebugMenuView: View {
    @StateObject private var viewModel = AudioRecorderViewModel()
    @State private var showAllRecordings = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Recorder").font(.headline)
            
            RecordingProgressView(viewModel: viewModel)
            
            ControlButtonsView(viewModel: viewModel)
            
            CurrentRecordingView(viewModel: viewModel)
            
            AllRecordingsListView(viewModel: viewModel, showAllRecordings: $showAllRecordings)
            
            ErrorMessageView(viewModel: viewModel)
        }
        .padding()
        .onAppear {
            viewModel.updateLocalRecordings()
        }
    }
}

class AudioRecorderViewModel: ObservableObject {
    @Published private(set) var audioState: AudioState
    @Published private(set) var speechAnalysisService: SpeechAnalysisService
    @Published private(set) var recordings: [RecordingViewModel] = []
    @Published var currentRecording: RecordingViewModel?
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.audioState = AudioState.shared
        self.speechAnalysisService = SpeechAnalysisService.shared

        setupBindings()
    }

    private func setupBindings() {
        audioState.$localRecordings
            .sink { [weak self] recordings in
                self?.updateRecordingViewModels(recordings)
            }
            .store(in: &cancellables)

        audioState.$currentRecording
            .sink { [weak self] recording in
                if let recording = recording {
                    self?.currentRecording = self?.recordings.first { $0.recording.id == recording.id }
                } else {
                    self?.currentRecording = nil
                }
            }
            .store(in: &cancellables)

        audioState.$errorMessage
            .sink { [weak self] message in
                self?.errorMessage = message
            }
            .store(in: &cancellables)

        speechAnalysisService.$errorMessage
            .sink { [weak self] message in
                if let message = message {
                    self?.errorMessage = message
                }
            }
            .store(in: &cancellables)
    }

    private func updateRecordingViewModels(_ recordings: [AudioRecording]) {
        self.recordings = recordings.map { recording in
            let viewModel = RecordingViewModel(recording: recording, speechAnalysisService: speechAnalysisService)
            viewModel.startAnalysis()
            return viewModel
        }
    }
    
    func fetchRecordings() {
        audioState.fetchRecordings()
    }
    func updateLocalRecordings() {
        audioState.updateLocalRecordings()
    }

    func toggleRecording() {
        audioState.toggleRecording()
    }

    func togglePlayback() {
        audioState.togglePlayback()
    }

    func deleteRecording(_ recording: RecordingViewModel) {
        audioState.deleteRecording(recording.recording)
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings.remove(at: index)
        }
    }

    var isRecording: Bool {
        audioState.isRecording
    }

    var isPlaying: Bool {
        audioState.isPlaying
    }

    var isPlaybackAvailable: Bool {
        audioState.isPlaybackAvailable
    }

    var recordingProgress: Double {
        audioState.recordingProgress
    }

    var formattedRecordingTime: String {
        audioState.formattedRecordingTime
    }

    func formattedFileSize(bytes: Int64) -> String {
        audioState.formattedFileSize(bytes: bytes)
    }
}

class RecordingViewModel: ObservableObject, Identifiable {
    let id: UUID
    let recording: AudioRecording
    @Published var speechProbability: Double?
    private let speechAnalysisService: SpeechAnalysisService
    private var cancellable: AnyCancellable?

    init(recording: AudioRecording, speechAnalysisService: SpeechAnalysisService) {
        self.id = recording.id
        self.recording = recording
        self.speechAnalysisService = speechAnalysisService
    }

    func startAnalysis() {
        cancellable = speechAnalysisService.$analysisProbabilities
            .map { $0[self.recording.url] }
            .assign(to: \.speechProbability, on: self)
    }
}

struct RecordingProgressView: View {
    @ObservedObject var viewModel: AudioRecorderViewModel
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(.blue)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(viewModel.recordingProgress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: viewModel.recordingProgress)

            VStack {
                Text(viewModel.formattedRecordingTime).font(.title2)
                Text(viewModel.isRecording ? "Recording..." : "Tap to Record")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .frame(width: 150, height: 150)
    }
}

struct ControlButtonsView: View {
    @ObservedObject var viewModel: AudioRecorderViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: viewModel.toggleRecording) {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                    .resizable().frame(width: 50, height: 50)
                    .foregroundColor(viewModel.isRecording ? .red : .blue)
            }

            Button(action: viewModel.togglePlayback) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable().frame(width: 50, height: 50)
                    .foregroundColor(.green)
            }
            .disabled(!viewModel.isPlaybackAvailable)
        }
    }
}

struct CurrentRecordingView: View {
    @ObservedObject var viewModel: AudioRecorderViewModel
    
    var body: some View {
        if let currentRecording = viewModel.currentRecording {
            RecordingInfoView(viewModel: currentRecording)
        }
    }
}


struct ErrorMessageView: View {
    @ObservedObject var viewModel: AudioRecorderViewModel
    
    var body: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage).font(.caption).foregroundColor(.red)
        }
    }
}
