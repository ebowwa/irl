// ContentView.swift
import SwiftUI
import Combine
import Foundation

struct ContentView: View {
    // Access shared state objects via @EnvironmentObject
    @EnvironmentObject var globalState: GlobalState
    @EnvironmentObject var audioState: AudioState
    @EnvironmentObject var backgroundAudio: BackgroundAudio
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    
    @State private var selectedTab = 0

    private let accentColor = Color("AccentColor")
    private let inactiveColor = Color.gray.opacity(0.6)
    private let backgroundColor = Color("BackgroundColor")

    // Gradient background for selected tabs
    private let gradient = LinearGradient(
        gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.7)]),
        startPoint: .leading,
        endPoint: .trailing
    )

    struct TabItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let selectedIcon: String
        let content: () -> AnyView
    }

    // Define the tabs with their respective content
    private let tabs: [TabItem] = [
        TabItem(title: "Live", icon: "waveform", selectedIcon: "waveform.fill") {
            AnyView(LiveView())
        },
        TabItem(title: "Arena", icon: "bubble.left.and.bubble.right", selectedIcon: "bubble.left.and.bubble.right.fill") {
            AnyView(ChatsView())
        }
    ]
    
    var body: some View {
        VStack {
            // Display the selected tab's content
            ZStack {
                if selectedTab == 0 {
                    LiveView() // Live view
                        .transition(.opacity)
                } else if selectedTab == 1 {
                    ChatsView() // Chat view
                        .transition(.opacity)
                }
            }
            Spacer()

            // Bottom Tab Buttons
            HStack(spacing: 4) { // Reduced spacing to make buttons nearly touch
                // Live button
                Button(action: {
                    withAnimation(.easeInOut) {
                        selectedTab = 0
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 0 ? "waveform.fill" : "waveform")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Live")
                            .font(.caption)
                            .bold() // Make title bold
                    }
                    .frame(maxWidth: .infinity, maxHeight: 40) // Adjust button size
                    .padding(.vertical, 8) // Reduced vertical padding
                    .background(
                        selectedTab == 0
                            ? gradient // Use gradient for selected state
                            : LinearGradient(gradient: Gradient(colors: [inactiveColor, inactiveColor]), startPoint: .leading, endPoint: .trailing) // Inactive state
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16) // More rounded corners
                    .shadow(color: selectedTab == 0 ? Color.black.opacity(0.2) : .clear, radius: 4, x: 0, y: 4)
                }

                // Chat button
                Button(action: {
                    withAnimation(.easeInOut) {
                        selectedTab = 1
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == 1 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Arena")
                            .font(.caption)
                            .bold() // Make title bold
                    }
                    .frame(maxWidth: .infinity, maxHeight: 40) // Adjust button size
                    .padding(.vertical, 8) // Reduced vertical padding
                    .background(
                        selectedTab == 1
                            ? gradient // Use gradient for selected state
                            : LinearGradient(gradient: Gradient(colors: [inactiveColor, inactiveColor]), startPoint: .leading, endPoint: .trailing) // Inactive state
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16) // More rounded corners
                    .shadow(color: selectedTab == 1 ? Color.black.opacity(0.2) : .clear, radius: 4, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 16) // Reduced horizontal padding
            .padding(.bottom, 12) // Added some space at the bottom
        }
        .background(backgroundColor)
        .edgesIgnoringSafeArea(.bottom) // Ensure content extends to the bottom
        .onAppear {
            setupAppearance()
            backgroundAudio.setupAudioSession()
        }
        // Remove redundant .environmentObject modifiers
        // .environmentObject(globalState)
        // .environmentObject(audioState)
        // .environmentObject(backgroundAudio)
        // .environmentObject(settingsViewModel)
        .preferredColorScheme(globalState.currentTheme == .dark ? .dark : .light)
    }

    /// Setup TabBar appearance
    private func setupAppearance() {
        UITabBar.appearance().backgroundColor = UIColor(backgroundColor)
        UITabBar.appearance().unselectedItemTintColor = UIColor(inactiveColor)
    }
}

extension Array {
    /// Safe array indexing to avoid out-of-bounds errors
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


// GlobalState.swift
enum Theme: String {
    case light, dark
}

class GlobalState: ObservableObject {
    @Published var user: User?
    @Published var notifications: [Notification] = []

    @AppStorage("currentTheme") var currentTheme: Theme = .light
    @AppStorage("selectedLanguageCode") private var selectedLanguageCode: String = "en"

    var selectedLanguage: AppLanguage {
        get {
            LanguageManager.shared.language(forCode: selectedLanguageCode) ?? AppLanguage(
                code: "en",
                name: "English",
                service: ["falwhisperSep2024", "anthropic-claude-3"]
            )
        }
        set {
            selectedLanguageCode = newValue.code
        }
    }

    private let userService: UserService
    private let notificationService: NotificationService

    init(userService: UserService = UserService(), notificationService: NotificationService = NotificationService()) {
        self.userService = userService
        self.notificationService = notificationService
        loadUser()
        fetchNotifications()
    }

    func loadUser() {
        userService.loadUser { [weak self] result in
            switch result {
            case .success(let user):
                self?.user = user
            case .failure(let error):
                print("Failed to load user: \(error)")
            }
        }
    }

    func fetchNotifications() {
        notificationService.fetchNotifications { [weak self] result in
            switch result {
            case .success(let notifications):
                self?.notifications = notifications
            case .failure(let error):
                print("Failed to fetch notifications: \(error)")
            }
        }
    }

    func toggleTheme() {
        currentTheme = currentTheme == .light ? .dark : .light
    }
}
