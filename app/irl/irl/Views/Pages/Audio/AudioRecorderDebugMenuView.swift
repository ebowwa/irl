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
    // Using @StateObject here to initialize and manage the lifecycle of AudioRecorderViewModel.
    // @StateObject ensures the view model is created once and persists while the view is in memory.
    @StateObject private var viewModel = AudioRecorderViewModel()
    
    // Local state for toggling the visibility of all recordings, managed via @State.
    @State private var showAllRecordings = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Recorder").font(.headline)
            
            // Displays recording progress, bound to the view model.
            RecordingProgressView(viewModel: viewModel)
            
            // Control buttons for recording and playback, bound to the view model.
            ControlButtonsView(viewModel: viewModel)
            
            // Displays the current recording's details, if available, from the view model.
            CurrentRecordingView(viewModel: viewModel)
            
            // List view for all recordings, which is also tied to the view model state.
            AllRecordingsListView(viewModel: viewModel, showAllRecordings: $showAllRecordings)
            
            // Error messages, if any, displayed by observing the view model's errorMessage property.
            ErrorMessageView(viewModel: viewModel)
        }
        .padding()
        // When the view appears, update local recordings by invoking the function in the view model.
        // This fetches the persisted recordings from disk or memory, ensuring state persistence.
        .onAppear {
            viewModel.updateLocalRecordings()
        }
    }
}

// Custom view for showing recording progress, observing changes in AudioRecorderViewModel's state.
struct RecordingProgressView: View {
    @ObservedObject var viewModel: AudioRecorderViewModel
    
    var body: some View {
        ZStack {
            // Background circle to represent full progress.
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(.blue)

            // Foreground circle showing the actual recording progress.
            Circle()
                .trim(from: 0.0, to: CGFloat(min(viewModel.recordingProgress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0)) // Rotates the circle to start from the top.
                .animation(.linear, value: viewModel.recordingProgress) // Smoothly animates progress changes.

            // Displays the current recording time and the recording status.
            VStack {
                Text(viewModel.formattedRecordingTime).font(.title2)
                Text(viewModel.isRecording ? "Recording..." : "Tap to Record")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .frame(width: 150, height: 150)
    }
}

// View containing control buttons for recording and playback.
struct ControlButtonsView: View {
    @ObservedObject var viewModel: AudioRecorderViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            // Button to start or stop recording.
            Button(action: viewModel.toggleRecording) {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                    .resizable().frame(width: 50, height: 50)
                    .foregroundColor(viewModel.isRecording ? .red : .blue)
            }

            // Button to start or pause playback.
            Button(action: viewModel.togglePlayback) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable().frame(width: 50, height: 50)
                    .foregroundColor(.green)
            }
            // Disable playback button if no recording is available to play.
            .disabled(!viewModel.isPlaybackAvailable)
        }
    }
}

// Displays information about the current recording, if available.
struct CurrentRecordingView: View {
    @ObservedObject var viewModel: AudioRecorderViewModel
    
    var body: some View {
        if let currentRecording = viewModel.currentRecording {
            RecordingInfoView(viewModel: currentRecording)
        }
    }
}

// Displays any error messages that may have been encountered.
struct ErrorMessageView: View {
    @ObservedObject var viewModel: AudioRecorderViewModel
    
    var body: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage).font(.caption).foregroundColor(.red)
        }
    }
}
