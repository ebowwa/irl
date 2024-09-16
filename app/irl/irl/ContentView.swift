// ContentView.swift
// TODO: if no server websocket not connected, etc - THEN save for later; add to queue batch for when possible
// want a testing mode - willing do do test backend
// ContentView.swift
import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var globalState = GlobalState()
    @StateObject private var audioState = AudioState.shared
    @AppStorage("isRecordingEnabled") private var isRecordingEnabled = false
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
        .preferredColorScheme(globalState.currentTheme == .dark ? .dark : .light)
    }

    private func setupAudioSession() {
        // Only start recording if it's enabled and not already recording
        if isRecordingEnabled {
            if !audioState.isRecording {
                audioState.startRecording()
            }
        } else {
            // Stop recording if it is disabled and currently recording
            if audioState.isRecording {
                audioState.stopRecording()
            }
        }
    }

    private func handleAppBackgrounding() {
        // Only continue recording if it's enabled
        if isRecordingEnabled {
            if !audioState.isRecording {
                audioState.startRecording()
            }
        } else {
            // Ensure recording is stopped when the app moves to the background
            if audioState.isRecording {
                audioState.stopRecording()
            }
        }
    }

    private func handleAppTermination() {
        // Always stop recording when the app terminates
        if audioState.isRecording {
            audioState.stopRecording()
        }
    }
}
