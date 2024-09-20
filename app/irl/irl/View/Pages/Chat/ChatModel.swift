//
//  ChatModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/20/24.
//

import Foundation

// MARK: - Chat Message Model
class ChatMessageObservable: ObservableObject, Identifiable {
    let id = UUID()
    @Published var content: String
    @Published var isUser: Bool
    @Published var timestamp: Date
    @Published var failed: Bool
    @Published var isSending: Bool // New property
    @Published var pluginName: String
    @Published var isSystem: Bool
    
    init(content: String, isUser: Bool, timestamp: Date, failed: Bool = false, isSending: Bool = false, pluginName: String = "", isSystem: Bool = false) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.failed = failed
        self.isSending = isSending
        self.pluginName = pluginName
        self.isSystem = isSystem
    }
}

// MARK: - Helper Struct for Alerts
struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}
