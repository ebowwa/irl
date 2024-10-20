import SwiftUI

struct AudioStateView: View {
    @EnvironmentObject var audioState: AudioState

    var body: some View {
        VStack(spacing: 20) {
            Text(audioState.isRecording ? "Recording in progress..." : "Not recording")
                .font(.headline)
                .foregroundColor(audioState.isRecording ? .red : .green)
            
            Text("Recording Time: \(audioState.formattedRecordingTime)")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            if audioState.isRecording {
                AudioLevelBar(level: audioState.audioLevelPublisher)  // Ensure this is AnyPublisher<Float, Never>
            }
            
            if audioState.isPlaybackAvailable {
                Button(action: {
                    audioState.togglePlayback()
                }) {
                    Text(audioState.isPlaying ? "Pause Playback" : "Play Recording")
                        .font(.headline)
                        .padding()
                        .background(audioState.isPlaying ? Color.orange : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            if let errorMessage = audioState.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 40) {
                Button(action: {
                    audioState.toggleRecording()
                }) {
                    Text(audioState.isRecording ? "Stop Recording" : "Start Recording")
                        .padding()
                        .background(audioState.isRecording ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    audioState.fetchRecordings()  // Ensure this method exists in AudioState
                }) {
                    Text("Load Recordings")
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            if !audioState.localRecordings.isEmpty {
                List(audioState.localRecordings) { recording in
                    HStack {
                        Text("Recording \(recording.id)")
                        Spacer()
                        Text(audioState.formattedFileSize(bytes: recording.fileSize))
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
    }
}




import SwiftUI
import Combine

// AudioLevelBar to show the current audio level using a progress bar
struct AudioLevelBar: View {
    @State private var audioLevel: Float = 0.0  // The current audio level, which updates over time
    let level: AnyPublisher<Float, Never>  // Publisher to receive audio level updates
    
    var body: some View {
        VStack {
            Text("Audio Level")  // Label to indicate what the bar represents
                .font(.caption)
            
            // Progress view to represent the audio level in real time
            ProgressView(value: Double(audioLevel), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())  // Use a linear style
                .frame(height: 10)  // Height of the bar
                .padding(.horizontal)
        }
        .onReceive(level) { newLevel in
            self.audioLevel = newLevel  // Update the state with the new audio level
        }
    }
}
