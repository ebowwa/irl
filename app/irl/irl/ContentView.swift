// ContentView.swift
import SwiftUI
import Combine
import Foundation

class GlobalState: ObservableObject {
    @Published var user: User?
    @Published var notifications: [Notification] = []
    @AppStorage("currentTheme") var currentTheme: Theme = .light
    @AppStorage("selectedLanguageCode") var selectedLanguageCode: String = "en"

    var selectedLanguage: AppLanguage {
        get {
            LanguageManager.shared.language(forCode: selectedLanguageCode) ?? AppLanguage(code: "en", name: "English", service: ["falwhisperSep2024", "anthropic-claude-3"])
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
