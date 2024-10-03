// irlApp.swift
import SwiftUI

@main
struct IRLApp: App {
    // Initialize your shared state objects here
    @StateObject private var globalState = GlobalState()
    @StateObject private var audioState = AudioState.shared
    @StateObject private var backgroundAudio = BackgroundAudio.shared
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalState)
                .environmentObject(audioState)
                .environmentObject(backgroundAudio)
                .environmentObject(settingsViewModel)
                // If you adopt additional managers (e.g., RecordingManager, PlaybackManager),
                // initialize and inject them here as well.
        }
    }
}
