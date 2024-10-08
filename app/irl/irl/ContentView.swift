import SwiftUI
import Combine
import Foundation

struct ContentView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var globalState: GlobalState
    @EnvironmentObject var audioState: AudioState
    @EnvironmentObject var backgroundAudio: BackgroundAudio
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    // MARK: - State
    @State private var selectedTab: Int = 0
    
    // MARK: - Colors
    private let accentColor = Color("AccentColor")
    private let inactiveColor = Color.gray.opacity(0.6)
    private let backgroundColor = Color("BackgroundColor")
    
    // MARK: - Gradient
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.7)]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - TabItem Definition
    struct TabItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let selectedIcon: String
        let content: () -> AnyView
        let showButtons: Bool // Add a flag to indicate if the buttons should be shown
    }
    
    // MARK: - Tabs Array
    private let tabs: [TabItem] = [
        TabItem(
            title: "Live",
            icon: "waveform",
            selectedIcon: "waveform.fill",
            content: { AnyView(LiveView()) },  // Provide content closure
            showButtons: true
        ),
        TabItem(
            title: "Arena",
            icon: "bubble.left.and.bubble.right",
            selectedIcon: "bubble.left.and.bubble.right.fill",
            content: { AnyView(SocialViewB()) },  // Provide content closure
            showButtons: true
        )
    ]
    
    // MARK: - Body
    var body: some View {
        VStack {
            // Selected Tab Content
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
            
            // Bottom Tab Buttons - Conditional based on `showButtons` flag
            if let currentTab = tabs[safe: selectedTab], currentTab.showButtons {
                HStack(spacing: 4) { // Reduced spacing to make buttons nearly touch
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
            // Ensure that the background audio session is set up and recording starts automatically if enabled
            if backgroundAudio.isBackgroundRecordingEnabled {
                backgroundAudio.startRecording() // Automatically start recording
            }
        }
        .preferredColorScheme(globalState.currentTheme == .dark ? .dark : .light)
    }
    
    // MARK: - Setup Appearance
    private func setupAppearance() {
        UITabBar.appearance().backgroundColor = UIColor(backgroundColor)
        UITabBar.appearance().unselectedItemTintColor = UIColor(inactiveColor)
    }
}

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

// MARK: - Array Safe Subscript Extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
