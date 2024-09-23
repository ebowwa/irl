//
//  ChatView.swift
//  irl
//
//  Created by Elijah Arbee on 9/20/24.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ClaudeViewModel
    @State private var message: String = ""
    @State private var messages: [ChatMessageObservable] = []
    @FocusState private var isInputFocused: Bool // what is this?
    @State private var showParametersModal = false // true will have the modal pop-up

    init() {
        _viewModel = StateObject(wrappedValue: ClaudeViewModel(apiClient: ClaudeAPIClient()))
    }

    var body: some View {
        ZStack {
            BackgroundView()
            VStack(spacing: 0) {
                ChatScrollView(
                    messages: groupedMessages,
                    onDelete: deleteMessage,
                    onStash: stashMessage,
                    onResend: resendMessage
                )
                InputView(message: $message, isInputFocused: $isInputFocused, onSend: sendMessage, isLoading: viewModel.isLoading)
            }
            ModalButton(showParametersModal: $showParametersModal)
        }
        .navigationTitle("Chat")
        .alert(item: Binding<AlertItem?>(
            get: { viewModel.error.map { AlertItem(message: $0) } },
            set: { _ in viewModel.error = nil }
        )) { alertItem in
            Alert(title: Text("Error"), message: Text(alertItem.message))
        }
        .sheet(isPresented: $showParametersModal) {
            // Create a ChatParametersViewModel from ClaudeViewModel
            ChatParametersModal(viewModel: ChatParametersViewModel(claudeViewModel: viewModel))
        }
        .onReceive(viewModel.$response) { response in
            if !response.isEmpty {
                appendFriendMessage(response)
            }
        }
    }

    // MARK: - Helper Methods
    private var groupedMessages: [(key: Date, value: [ChatMessageObservable])] {
        messages.groupByDate()
    }

    private func appendFriendMessage(_ response: String) {
        let friendMessage = ChatMessageObservable(content: response, isUser: false, timestamp: Date())
        messages.append(friendMessage)
    }

    private func deleteMessage(_ message: ChatMessageObservable) {
        messages.removeAll(where: { $0.id == message.id })
    }

    private func stashMessage(_ message: ChatMessageObservable) {
        // Implement stash functionality here
        print("Stashed message: \(message.content)")
    }

    private func sendMessage() {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        let userMessage = ChatMessageObservable(content: trimmedMessage, isUser: true, timestamp: Date(), isSending: true)
        messages.append(userMessage)
        viewModel.sendMessage(userMessage) { success in
            userMessage.isSending = false
            if !success {
                userMessage.failed = true
            }
        }
        message = ""
        isInputFocused = false
    }

    private func resendMessage(_ message: ChatMessageObservable) {
        guard !message.isSending else { return } // Prevent multiple resend attempts
        message.isSending = true
        message.failed = false
        viewModel.sendMessage(message) { success in
            message.isSending = false
            if !success {
                message.failed = true
            }
        }
    }
}


extension Array where Element == ChatMessageObservable {
    func groupByDate() -> [(key: Date, value: [ChatMessageObservable])] {
        let grouped = Dictionary(grouping: self) { message in
            Calendar.current.startOfDay(for: message.timestamp)
        }
        return grouped.sorted { $0.key < $1.key }
    }
}

// MARK: - Modal Button View
struct ModalButton: View {
    @Binding var showParametersModal: Bool
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { showParametersModal = true }) {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
            Spacer()
        }
    }
}

// MARK: - Background View
struct BackgroundView: View {
    var body: some View {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
    }
}


//  TODO: for the AI name i want it to say the plugin name if a system prompt and plugin is in use i.e. Moo GPT not saying friend
//  make more imessage like
//
// i want this to look more like imessage with the `plugins/bubbles` as the favorited contacts
