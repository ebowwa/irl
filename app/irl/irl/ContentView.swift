//
//  ContentView.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var globalState = GlobalState()
    @StateObject private var audioState = AudioState.shared
    @AppStorage("isRecordingEnabled") private var isRecordingEnabled = true
    @State private var selectedTab = 0

    // App-wide customizable properties
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
        .onAppear {
            if isRecordingEnabled {
                audioState.startRecording()
            }
        }
        .onDisappear {
            audioState.stopRecording()
        }
    }
} 
