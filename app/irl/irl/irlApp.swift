//
//  IRLApp.swift - with the openaudiostandard framework
//  IRL
//

import SwiftUI
import Combine
import Foundation

// MARK: - Main Application Entry Point

@main
struct IRLApp: App {
    @StateObject private var globalState = GlobalState()
    @StateObject private var audioState = AudioState.shared

    var body: some Scene {
        WindowGroup {
            AppEntryPathContentView()
                .environmentObject(globalState)
                .environmentObject(audioState)
        }
    }
}

// MARK: - Router Destination Enum

enum RouterDestination: Identifiable {
    case geminiChat
    case socialFeed
    case settings

    var id: UUID { UUID() } // Abstracted UUID generation
}

// MARK: - Router ViewModel

class RouterViewModel: ObservableObject {
    @Published var currentDestination: RouterDestination?

    func navigate(to destination: RouterDestination) { currentDestination = destination }
    func dismiss() { currentDestination = nil }
}

// MARK: - Main Content View with Router Integration

struct AppEntryPathContentView: View {
    @EnvironmentObject var globalState: GlobalState
    @EnvironmentObject var audioState: AudioState

    @State private var selectedTab: Int = 0
    @StateObject private var router = RouterViewModel()

    // Only abstracted relevant state details that relate to navigation or important tabs
    @StateObject private var socialFeedViewModel = SocialFeedViewModel(posts: [])
    @State private var isMenuOpen = false
    @State private var demoMode: Bool = true
    @State private var showSettingsView = false
    @State private var isRecording: Bool = false
    @State private var isSpeechActive: Bool = false
    @State private var showModelStatusAlert: Bool = false
    @State private var modelStatusMessage: String = ""

    private let accentColor = Color("AccentColor")
    private let inactiveColor = Color.gray.opacity(0.6)
    private let backgroundColor = Color("BackgroundColor")
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.7)]),
        startPoint: .leading,
        endPoint: .trailing
    )

    private var tabs: [TabItem] {  // Abstracted tabs into computed property
        [
            TabItem(
                title: "Live",
                icon: "waveform",
                selectedIcon: "waveform.badge.microphone",
                content: { AnyView(GeminiChatView()) },
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

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    if let currentTab = tabs[safe: selectedTab] {
                        currentTab.content().transition(.opacity)
                    } else {
                        Text("Other Content").transition(.opacity)
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
                                withAnimation(.easeInOut) { selectedTab = index }
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
                handleAudioSetup()
                loadData()
            }
            .preferredColorScheme(globalState.currentTheme == .dark ? .dark : .light)
            .sheet(isPresented: $showSettingsView) { SettingsView() }
            .alert(isPresented: $showModelStatusAlert) {
                Alert(
                    title: Text(modelStatusMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationDestination(for: RouterDestination.self) { destination in
                navigate(to: destination)
            }
            .environmentObject(router)
        }
    }

    private func setupAppearance() {
        UITabBar.appearance().backgroundColor = UIColor(backgroundColor)
        UITabBar.appearance().unselectedItemTintColor = UIColor(inactiveColor)
    }

    private func handleAudioSetup() {
        if audioState.isBackgroundRecordingEnabled {
            audioState.startRecording(manual: false)
            isRecording = true
        }
    }

    private func shouldShowTabs(for selectedIndex: Int) -> Bool {
        tabs[safe: selectedIndex]?.showButtons ?? false
    }

    private func loadData() {
        if demoMode { socialFeedViewModel.loadDemoData() }
        else { /* Handle real data loading */ }
    }

    @ViewBuilder
    private func navigate(to destination: RouterDestination) -> some View {
        switch destination {
        case .geminiChat:
            GeminiChatView()
        case .socialFeed:
            SocialFeedView(
                viewModel: socialFeedViewModel,
                isMenuOpen: $isMenuOpen,
                demoMode: $demoMode,
                showSettingsView: $showSettingsView
            )
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Array Safe Subscript Extension

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
