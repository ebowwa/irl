import SwiftUI

struct AudioStateView: View {

    // Access the shared audio state via environment object
    @EnvironmentObject var audioState: AudioState  // Use EnvironmentObject wrapper to access shared state

    var body: some View {
        VStack(spacing: 20) {
            
            // Recording status
            Text(audioState.isRecording ? "Recording in progress..." : "Not recording")
                .font(.headline)
                .foregroundColor(audioState.isRecording ? .red : .green)
            
            // Display recording time
            Text("Recording Time: \(audioState.formattedRecordingTime)")
                .font(.subheadline)
                .foregroundColor(.primary)
            
            // Show audio levels while recording
            if audioState.isRecording {
                AudioLevelBar(level: audioState.audioLevelPublisher)
            }
            
            // Playback availability
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
            
            // Display error messages if any
            if let errorMessage = audioState.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            // Control buttons for recording
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
                    audioState.fetchRecordings() // Fetch recordings from storage
                }) {
                    Text("Load Recordings")
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            
            // Display list of saved recordings
            if !audioState.localRecordings.isEmpty {
                List(audioState.localRecordings) { recording in
                    HStack {
                        Text("Recording \(recording.id)")  // Display recording info
                        Spacer()
                        Text(audioState.formattedFileSize(bytes: recording.fileSize))
                    }
                }
                .frame(height: 200)  // Optional: limit the frame height for the list
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
