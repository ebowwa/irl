import SwiftUI
import Combine
import Foundation

// ContentView.swift
struct ContentView: View {
    @StateObject private var globalState = GlobalState()
    @StateObject private var audioState = AudioState.shared
    @StateObject private var backgroundAudio = BackgroundAudio.shared
    @StateObject private var settingsViewModel = SettingsViewModel() // Integrated SettingsViewModel
    
    @State private var selectedTab = 0

    private let accentColor = Color("AccentColor")
    private let inactiveColor = Color.gray
    private let backgroundColor = Color("BackgroundColor")

    struct TabItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let selectedIcon: String
        let content: () -> AnyView
    }

    // Define the tabs with their respective content
    private let tabs: [TabItem] = [
        TabItem(title: "Live", icon: "waveform", selectedIcon: "waveform") {
            AnyView(EmotionAnalysisDashboard())
        },
        // Uncomment and define Home tab when needed
        // TabItem(title: "Home", icon: "house", selectedIcon: "house.fill") {
        //     AnyView(HomeView(showSettings: /* Binding */))
        // },
        TabItem(title: "Chats", icon: "bubble.left.and.bubble.right", selectedIcon: "bubble.left.and.bubble.right.fill") {
            AnyView(SocialFeedView())
        }
    ]

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(tabs.indices, id: \.self) { index in
                tabContent(for: index, content: tabs[index].content)
                    .tabItem {
                        customTabItem(for: tabs[index], isSelected: selectedTab == index)
                    }
                    .tag(index)
            }
        }
        .accentColor(accentColor)
        .onAppear {
            setupAppearance()
            backgroundAudio.setupAudioSession()
        }
        .environmentObject(globalState)
        .environmentObject(audioState)
        .environmentObject(backgroundAudio)
        .environmentObject(settingsViewModel) // Inject settingsViewModel into environment
        .preferredColorScheme(globalState.currentTheme == .dark ? .dark : .light)
    }

    /// View builder to create tab content with navigation
    @ViewBuilder
    private func tabContent(for index: Int, content: () -> AnyView) -> some View {
        NavigationView {
            content()
                .navigationTitle(tabs[safe: index]?.title ?? "Tab")
                // Add any common navigation modifiers or toolbar items here
        }
    }

    /// Custom tab item view
    private func customTabItem(for tab: TabItem, isSelected: Bool) -> some View {
        VStack {
            Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                .font(.system(size: 20, weight: .semibold))
            Text(tab.title)
                .font(.caption)
        }
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
