//
//  GlobalState.swift
//  irl
// TODO: user management, remove the placeholders still contemplating firebase v supabase and co
//  Created by Elijah Arbee on 8/29/24.
//
import SwiftUI

class GlobalState: ObservableObject {
    @Published var user: User?
    @Published var notifications: [Notification] = []
    @AppStorage("currentTheme") var currentTheme: Theme = .light
    @AppStorage("selectedLanguage") var selectedLanguage: Language = .english

    init() {
        loadUser()
        fetchNotifications()
    }

    func loadUser() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.user = User(id: UUID(), name: "John Doe", email: "john@example.com")
        }
    }

    func fetchNotifications() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.notifications = [
                Notification(id: UUID(), title: "New message", body: "You have a new message from Jane"),
                Notification(id: UUID(), title: "Reminder", body: "Team meeting at 3 PM")
            ]
        }
    }

    func toggleTheme() {
        currentTheme = currentTheme == .light ? .dark : .light
    }
}
