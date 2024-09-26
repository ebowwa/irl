// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var globalState = GlobalState()
    @StateObject private var audioState = AudioState.shared
    @StateObject private var backgroundAudio = BackgroundAudio.shared
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
        .environmentObject(backgroundAudio)
        .onAppear(perform: backgroundAudio.setupAudioSession)
        .preferredColorScheme(globalState.currentTheme == .dark ? .dark : .light)
    }
}

// TODO:
// - if no server websocket not connected, etc - THEN save for later; add to queue batch for when possible
// - want a testing mode - willing do do test backend _ solved with false to isRecordingEnabled
// - maybe modularize to a background audioservices or so and contentview
// - ANSWER QUESTION: How do i use the recorded audio or the recording audio in my app ?
