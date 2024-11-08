// LiveViewModel.swift
// irl
//
// Created by Elijah Arbee on 10/10/24.

import SwiftUI
import Combine

class LiveViewModel: ObservableObject {
    // Published properties to notify the view of changes
    @Published var selectedWord: String? = nil
    @Published var selectedSentence: String? = nil
    @Published var activeConnection: ConnectionType? = nil
    @Published var chatData: [ChatMessage] = []

    // Enum for connection types
    enum ConnectionType {
        case ble, wifi, other
    }

    // Initializer
    init() {
        loadData()
        simulateConnectionStates()
    }

    // Load chat data (Assuming loadChatData is defined in Utils.swift)
    func loadData() {
        chatData = loadChatData()
    }

    // Simulate connection state changes
    func simulateConnectionStates() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.activeConnection = .wifi
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.activeConnection = .ble
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            self.activeConnection = .other
        }
    }
}
