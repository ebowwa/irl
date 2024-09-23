//
//  ChatMessageObservable.swift
//  irl
//  ClaudeViewModel handles the logic for sending and receiving messages & ChatMessageObservable instances represent the state of each message within the UI.
//  Created by Elijah Arbee on 9/22/24.
//

import Foundation

// MARK: - Chat Message Model
class ChatMessageObservable: ObservableObject, Identifiable {
    let id = UUID()
    @Published var content: String
    @Published var isUser: Bool
    @Published var timestamp: Date
    @Published var failed: Bool
    @Published var isSending: Bool
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

