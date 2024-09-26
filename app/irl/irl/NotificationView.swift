//
//  NotificationView.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
import Foundation

struct Notification: Identifiable {
    let id: UUID
    let title: String
    let body: String
}
// allow the models running inference to store 'todos' with notifications for the future or real-time
// generate the uuid on device and use delimiters to segment llm response i.e. (delimiter) title: "walk dog" , body "go walk tom like you promised Jerome, take your scooter you both will enjoy it"

class NotificationService {
    func fetchNotifications(completion: @escaping (Result<[Notification], Error>) -> Void) {
        // Simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let notifications = [
                Notification(id: UUID(), title: "New message", body: "You have a new message from Jane"),
                Notification(id: UUID(), title: "Reminder", body: "Team meeting at 3 PM")
            ]
            completion(.success(notifications))
        }
    }
}
