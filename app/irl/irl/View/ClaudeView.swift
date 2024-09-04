//
//  ClaudeView.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import SwiftUI

struct ClaudeView: View {
    @StateObject private var viewModel: ClaudeViewModel
    @State private var message: String = ""
    @FocusState private var isInputFocused: Bool
    
    init() {
        _viewModel = StateObject(wrappedValue: ClaudeViewModel(apiClient: ClaudeAPIClient()))
    }
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !viewModel.response.isEmpty {
                            responseView
                        }
                    }
                    .padding()
                }
                
                inputView
            }
        }
        .navigationTitle("Chat with Claude")
    }
    
    private var responseView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Claude")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(viewModel.response)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }
    
    private var inputView: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Type your message...", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                    .padding(.horizontal)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(message.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(20)
                }
                .disabled(message.isEmpty || viewModel.isLoading)
                .padding(.trailing)
            }
            .padding(.top)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: -2)
            
            if viewModel.isLoading {
                ProgressView()
                    .padding(.bottom)
            }
        }
        .padding(.vertical, 10)
        .background(Color.white)
    }
    
    private func sendMessage() {
        viewModel.sendMessage(message)
        message = ""
        isInputFocused = false
    }
}
