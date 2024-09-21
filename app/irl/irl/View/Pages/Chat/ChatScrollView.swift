//
//  ChatScrollView.swift
//  irl
//
//  Created by Elijah Arbee on 9/20/24.
// Corrected the resend

import SwiftUI

// MARK: - Chat Scroll View
struct ChatScrollView: View {
    let messages: [(key: Date, value: [ChatMessageObservable])]
    let onDelete: (ChatMessageObservable) -> Void
    let onStash: (ChatMessageObservable) -> Void
    let onResend: (ChatMessageObservable) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(messages, id: \.key) { date, messagesForDate in
                    Section(header: DaySeparator(date: date)) {
                        ForEach(messagesForDate) { chatMessage in
                            MessageView(chatMessage: chatMessage, onResend: onResend)
                                .swipeActions(edge: .leading) {
                                    Button(action: { onStash(chatMessage) }) {
                                        Label("Stash", systemImage: "archivebox")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive, action: { onDelete(chatMessage) }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Day Separator View
struct DaySeparator: View {
    let date: Date
    
    var body: some View {
        HStack {
            Capsule()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)
                .overlay(
                    Text(DateHelper.shared.formatForSeparator(date: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .background(Color.gray.opacity(0.1))
                )
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Message View with Double Tap to Resend
struct MessageView: View {
    @ObservedObject var chatMessage: ChatMessageObservable
    let onResend: (ChatMessageObservable) -> Void

    var body: some View {
        VStack(alignment: chatMessage.isUser ? .trailing : .leading, spacing: 8) {
            HStack {
                if chatMessage.isUser {
                    Spacer()
                }
                Text(chatMessage.isUser ? "You" : (chatMessage.isSystem ? getPluginName() : "Friend"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(DateHelper.shared.formatTime(date: chatMessage.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !chatMessage.isUser {
                    Spacer()
                }
            }
            HStack {
                if chatMessage.failed && chatMessage.isUser {
                    Button(action: {
                        onResend(chatMessage)
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.red)
                    .clipShape(Circle())
                }
                Text(chatMessage.content)
                    .padding()
                    .background(chatMessageBackground())
                    .foregroundColor(chatMessage.isUser ? .white : .black)
                    .cornerRadius(12)
                if chatMessage.isSending && chatMessage.isUser {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .padding(.leading, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: chatMessage.isUser ? .trailing : .leading)
            // Add Double-Tap Gesture
            .onTapGesture(count: 2) {
                if chatMessage.failed && chatMessage.isUser {
                    onResend(chatMessage)
                }
            }
        }
    }
    
    private func chatMessageBackground() -> Color {
        if chatMessage.failed {
            return Color.red.opacity(0.7)
        }
        return chatMessage.isUser ? Color.blue : Color.white
    }
    
    private func getPluginName() -> String {
        return chatMessage.pluginName.isEmpty ? "Friend" : chatMessage.pluginName
    }
}


// MARK: - Input View with Greyed-Out File and Image Attachments (maybe not show the image and attachments just upfront but maybe three dots and then click to widget to upload image or attachment like modern imessage)
struct InputView: View {
    @Binding var message: String
    @FocusState.Binding var isInputFocused: Bool
    let onSend: () -> Void
    let isLoading: Bool
    
    @State private var showAttachmentOptions = false // State to control attachment visibility

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Attachment Widget
                Button(action: {
                    showAttachmentOptions.toggle() // Toggle visibility
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(10)
                }
                .padding(.leading)

                // Conditionally show attachment buttons
                if showAttachmentOptions {
                    // File Attachment Button
                    Button(action: {
                        // openFilePicker()
                    }) {
                        Image(systemName: "paperclip")
                            .foregroundColor(.gray)
                            .padding(10)
                    }
                    .disabled(true) // Greyed out
                    .padding(.leading)

                    // Image Attachment Button
                    Button(action: {
                        // openImagePicker()
                    }) {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .padding(10)
                    }
                    .disabled(true) // Greyed out
                    .padding(.leading)
                }

                // Text Field for the Message Input
                TextField("Type your message...", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                    .padding(.horizontal)

                // Send Button
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(message.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(20)
                }
                .disabled(message.isEmpty || isLoading)
                .padding(.trailing)
            }
            .padding(.top)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: -2)
            
            // Show loading indicator if necessary
            if isLoading {
                ProgressView()
                    .padding(.bottom)
            }
        }
        .padding(.vertical, 10)
        .background(Color.white)
    }
}
    
    // Placeholder function for image picker (to be implemented later)
    /*
    private func openImagePicker() {
        // Image picker logic to be added here once API is ready
    }

    // Placeholder function for file picker (to be implemented later)
    private func openFilePicker() {
        // File picker logic to be added here once API is ready
    }
    */

