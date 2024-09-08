import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var globalState = GlobalState()
    @StateObject private var audioState = AudioState.shared
    @AppStorage("isRecordingEnabled") private var isRecordingEnabled = true
    @State private var selectedTab = 0

    let accentColor: Color = Color("AccentColor")
    let inactiveColor: Color = .gray
    let backgroundColor: Color = Color("BackgroundColor")

    var body: some View {
        MainTabMenu(
            selectedTab: $selectedTab,
            accentColor: accentColor,
            inactiveColor: inactiveColor,
            backgroundColor: backgroundColor
        )
        .environmentObject(globalState)
        .environmentObject(audioState)
        .onAppear(perform: setupAudioSession)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            handleAppBackgrounding()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
            handleAppTermination()
        }
    }

    private func setupAudioSession() {
        if isRecordingEnabled && !audioState.isRecording {
            audioState.startRecording()
        }
    }

    private func handleAppBackgrounding() {
        // Ensure recording continues in the background if enabled
        if isRecordingEnabled && !audioState.isRecording {
            audioState.startRecording()
        }
    }

    private func handleAppTermination() {
        // Stop recording and perform any necessary cleanup
        if audioState.isRecording {
            audioState.stopRecording()
        }
    }
}
