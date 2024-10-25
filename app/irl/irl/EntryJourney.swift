//
//  EntryJourney.swift
//  IRL
//
//  Created by Elijah Arbee on 10/23/24.
//
// File 1: TabItem.swift

import SwiftUI
import Foundation

// MARK: - TabItem Struct
struct TabItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let selectedIcon: String
    let content: () -> AnyView
    let showButtons: Bool // Indicates if buttons should be shown for this tab
}

// File 2: TabButton.swift

import SwiftUI

// MARK: - TabButton View
struct TabButton: View {
    let title: String
    let icon: String
    let selectedIcon: String
    let isSelected: Bool
    let gradient: LinearGradient
    let inactiveColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.caption)
                    .bold()
            }
            .frame(maxWidth: .infinity, maxHeight: 40)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? gradient
                    : LinearGradient(
                        gradient: Gradient(colors: [inactiveColor, inactiveColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                      )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: isSelected ? Color.black.opacity(0.2) : .clear, radius: 4, x: 0, y: 4)
        }
    }
}

//
//  EntryJourneyView.swift
//  IRL
//
//  Created by Elijah Arbee on 10/24/24.
//


// File 3: EntryJourneyView.swift
import SwiftUI
import Combine
import Foundation

struct EntryJourneyView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var globalState: GlobalState
    @EnvironmentObject var audioState: AudioState
    
    // MARK: - State
    @State private var selectedTab: Int = 0
    @State private var areTabsVisible: Bool = true // State to control tab visibility
    @StateObject private var socialFeedViewModel = SocialFeedViewModel(posts: [])
    @State private var isMenuOpen = false
    @State private var demoMode: Bool = true
    @State private var showSettingsView = false
    
    // Audio-Related State
    @State private var isRecording: Bool = false
    @State private var isSpeechActive: Bool = false
    
    // Speech Recognition Manager
    //@StateObject private var speechRecognitionManager = SpeechRecognitionManager.shared
    
    // Modal State Variables
    @State private var showModelStatusAlert: Bool = false
    @State private var modelStatusMessage: String = ""
    
    // MARK: - Colors & Gradient
    private let accentColor = Color("AccentColor")
    private let inactiveColor = Color.gray.opacity(0.6)
    private let backgroundColor = Color("BackgroundColor")
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.7)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Computed Tabs Array
    private var tabs: [TabItem] {
        [
            TabItem(
                title: "Live",
                icon: "waveform",
                selectedIcon: "waveform.badge.microphone",
                content: { AnyView(SimpleLocalTranscription()) },
                showButtons: true
            ),
            TabItem(
                title: "Social",
                icon: "person.2",
                selectedIcon: "person.2.fill",
                content: { AnyView(SocialFeedView(
                    viewModel: socialFeedViewModel,
                    isMenuOpen: $isMenuOpen,
                    demoMode: $demoMode,
                    showSettingsView: $showSettingsView
                )) },
                showButtons: true
            )
        ]
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            ZStack {
                if let currentTab = tabs[safe: selectedTab] {
                    currentTab.content()
                        .transition(.opacity)
                } else {
                    Text("Other Content")
                        .transition(.opacity)
                }
            }
            Spacer()
            
            if shouldShowTabs(for: selectedTab) {
                HStack(spacing: 4) {
                    ForEach(tabs.indices, id: \.self) { index in
                        let tab = tabs[index]
                        TabButton(
                            title: tab.title,
                            icon: tab.icon,
                            selectedIcon: tab.selectedIcon,
                            isSelected: selectedTab == index,
                            gradient: gradient,
                            inactiveColor: inactiveColor
                        ) {
                            withAnimation(.easeInOut) {
                                selectedTab = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(backgroundColor)
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            setupAppearance()
            handleAudioSetup() // Centralized function for audio setup
            loadData()
            // speechRecognitionManager.requestSpeechAuthorization()
        }
        .onDisappear {
            // handleAudioTeardown() - Removed this line
        }

        .preferredColorScheme(globalState.currentTheme == .dark ? .dark : .light)
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
        }
        //.onReceive(speechRecognitionManager.$isSpeechDetected) { isDetected in
        //    updateModelStatus(isActive: isDetected)
        //}
        .alert(isPresented: $showModelStatusAlert) {
            Alert(
                title: Text(modelStatusMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Audio Setup & Teardown
    private func handleAudioSetup() {
        if audioState.isBackgroundRecordingEnabled {
            audioState.startRecording(manual: false)
            isRecording = true
        }
    }
    
    // Remove the entire function
    /*
    private func handleAudioTeardown() {
        if isRecording {
            audioState.stopRecording()
            isRecording = false
        }
    }
    */


    // MARK: - Setup Appearance
    private func setupAppearance() {
        UITabBar.appearance().backgroundColor = UIColor(backgroundColor)
        UITabBar.appearance().unselectedItemTintColor = UIColor(inactiveColor)
    }

    // MARK: - Modular Approach for Tab Visibility
    private func shouldShowTabs(for selectedIndex: Int) -> Bool {
        guard let currentTab = tabs[safe: selectedIndex] else { return false }
        return currentTab.showButtons
    }

    // MARK: - Load Data Function
    private func loadData() {
        if demoMode {
            socialFeedViewModel.loadDemoData()
        } else {
            // Load real data
        }
    }
    
    // MARK: - Update Model Status
    private func updateModelStatus(isActive: Bool) {
        if isActive {
            modelStatusMessage = "Speech Recognition Active"
        } else {
            modelStatusMessage = "Speech Recognition Not Active"
        }
        showModelStatusAlert = true
    }
}



// MARK: - Array Safe Subscript Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

