//
//  GlobalState.swift
//  irl
//
//  Created by Elijah Arbee on 9/25/24.
//
import SwiftUI
import Combine
import Foundation

enum Theme: String {
    case light, dark
}

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
