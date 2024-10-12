//
//  GlobalState.swift
//  irl
//
//  Created by Elijah Arbee on 10/3/24.
//

import SwiftUI
import Combine
import Foundation
// GlobalState.swift
enum Theme: String {
    case light, dark
}

class GlobalState: ObservableObject {
    @Published var user: User?
    @Published var notifications: [Notification] = []
    @Published var showTabBar: Bool = true

    @AppStorage("currentTheme") var currentTheme: Theme = .light
    /**@AppStorage("selectedLanguageCodes") private var selectedLanguageCodes: [String] = ["en"]

    var selectedLanguages: [AppLanguage] {
        get {
            selectedLanguageCodes.compactMap {
                LanguageManager.shared.language(forCode: $0) ?? AppLanguage(
                    code: "en",
                    name: "English",
                    service: ["falwhisperSep2024", "anthropic-claude-3"] // Optional [String]?
                )
            }
        }
        set {
            selectedLanguageCodes = newValue.map { $0.code }
        }
    }

*/
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
