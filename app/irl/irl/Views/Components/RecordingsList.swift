//
//  RecordingsList.swift
//  irl
//
//  Created by Elijah Arbee on 9/7/24.
//

import SwiftUI

struct AllRecordingsListView: View {
    @ObservedObject var viewModel: AudioRecorderViewModel
    @Binding var showAllRecordings: Bool
    
    var body: some View {
        VStack {
            Button(showAllRecordings ? "Hide All Recordings" : "Show All Recordings") {
                showAllRecordings.toggle()
            }
            .padding(.top)
            
            if showAllRecordings {
                recordingsList
            }
        }
    }
    
    private var recordingsList: some View {
        Group {
            if viewModel.recordings.isEmpty {
                Text("No recordings available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.recordings) { recording in
                        RecordingInfoView(viewModel: recording)
                    }
                    .onDelete(perform: deleteRecordings)
                }
                .frame(height: 200)
            }
        }
    }
    
    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteRecording(viewModel.recordings[index])
        }
    }
}

struct RecordingInfoView: View {
    @ObservedObject var viewModel: RecordingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.recording.url.lastPathComponent)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text("Size: \(formattedFileSize(bytes: viewModel.recording.fileSize))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Created: \(formattedDate(date: viewModel.recording.creationDate))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Display Transcribed Text
            if !viewModel.transcribedText.isEmpty && viewModel.transcribedText != "Transcription will appear here." {
                Text("Transcription: \(viewModel.transcribedText)")
                    .font(.body)
                    .foregroundColor(.primary)
            } else {
                Text("Transcribing...")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formattedFileSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
