import SwiftUI
import Combine
import AVFoundation

class GeminiChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var chatLog: [String] = []
    @Published var messageInput: String = ""
    @Published var isConnected: Bool = false
    @Published var isRecording: Bool = false
    @Published var transcription: String = ""
    @Published var audioLevel: Float = 0.0
    @Published var errorMessage: String? = nil
    
    // MARK: - Private Properties
    private var cancellables: Set<AnyCancellable> = []
    private let audioState = AudioState.shared
    private let transcriptionManager = TranscriptionManager.shared
    private let openAudioManager = OpenAudioManager.shared
    private let deviceManager = DeviceManager.shared
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Setup Bindings
    private func setupBindings() {
        // Bind to transcription updates
        transcriptionManager.$lastTranscribedText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcription in
                guard let self = self, !transcription.isEmpty else { return }
                self.appendMessage(sender: "Gemini", message: transcription)
            }
            .store(in: &cancellables)
        
        // Bind to audio level updates
        audioState.audioLevelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.audioLevel = level
                // Optionally, update UI elements like volume meters
            }
            .store(in: &cancellables)
        
        // Bind to error messages
        audioState.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.appendMessage(sender: "Error", message: error)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - WebSocket Management
    func connectWebSocket() {
        guard !isConnected else { return }
        let url = URL(string: "wss://8beb-50-247-127-70.ngrok-free.app/api/gemini/ws/chat")!
        openAudioManager.setupWebSocket(url: url)
        
        // Subscribe to incoming WebSocket messages via AudioState
        audioState.$currentRecording
            .compactMap { $0?.transcription }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcription in
                self?.appendMessage(sender: "Gemini", message: transcription)
            }
            .store(in: &cancellables)
        
        isConnected = true
        appendMessage(sender: "System", message: "Connected to Gemini Chat.")
    }
    
    func disconnectWebSocket() {
        guard isConnected else { return }
        openAudioManager.stopStreaming()
        openAudioManager.stopRecording()
        isConnected = false
        appendMessage(sender: "System", message: "Disconnected from Gemini Chat.")
    }
    
    // MARK: - Messaging
    func sendMessage() {
        guard !messageInput.isEmpty, isConnected else { return }
        
        // Construct JSON message
        let messageDict: [String: Any] = [
            "role": "user",
            "text": messageInput,
            "type": "text"
        ]
        guard let messageData = try? JSONSerialization.data(withJSONObject: messageDict, options: []),
              let messageString = String(data: messageData, encoding: .utf8) else {
            appendMessage(sender: "Error", message: "Failed to serialize message.")
            return
        }
        
        // Send message via WebSocket
        audioState.webSocketManager?.sendAudioData(Data(messageString.utf8))
        appendMessage(sender: "You", message: messageInput)
        messageInput = ""
    }
    
    // MARK: - Audio Recording
    func startRecording() {
        guard isConnected else {
            appendMessage(sender: "Error", message: "WebSocket is not connected.")
            return
        }
        openAudioManager.startRecording(manual: true)
        isRecording = true
        appendMessage(sender: "System", message: "Started recording audio...")
    }
    
    func stopRecording() {
        openAudioManager.stopRecording()
        isRecording = false
        appendMessage(sender: "System", message: "Stopped recording audio.")
        
        // Access the current recording URL and send audio
        if let recordingURL = audioState.currentRecordingURL(),
           let audioData = try? Data(contentsOf: recordingURL),
           let webSocketManager = audioState.webSocketManager {
            
            let base64Audio = audioData.base64EncodedString()
            let messageDict: [String: Any] = [
                "role": "user",
                "audio": base64Audio,
                "type": "audio"
            ]
            guard let messageData = try? JSONSerialization.data(withJSONObject: messageDict, options: []),
                  let messageString = String(data: messageData, encoding: .utf8) else {
                appendMessage(sender: "Error", message: "Failed to serialize audio message.")
                return
            }
            
            webSocketManager.sendAudioData(Data(messageString.utf8))
            appendMessage(sender: "System", message: "Audio message sent.")
        } else {
            appendMessage(sender: "Error", message: "No audio recording found to send.")
        }
    }
    
    // MARK: - Helper Methods
    private func appendMessage(sender: String, message: String) {
        DispatchQueue.main.async {
            self.chatLog.append("\(sender): \(message)")
        }
    }
}
import SwiftUI

struct GeminiChatView: View {
    @StateObject private var viewModel = GeminiChatViewModel()
    
    var body: some View {
        VStack {
            Text("Gemini Chat")
                .font(.largeTitle)
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.chatLog, id: \.self) { message in
                        HStack(alignment: .top) {
                            Text(message)
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: 300)
            .border(Color.gray, width: 1)
            .padding()
            
            TextField("Enter your message here...", text: $viewModel.messageInput, onCommit: viewModel.sendMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .disabled(!viewModel.isConnected)
            
            HStack {
                Button(action: viewModel.sendMessage) {
                    Text("Send Text")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .disabled(!viewModel.isConnected || viewModel.messageInput.isEmpty)
                .background(viewModel.isConnected && !viewModel.messageInput.isEmpty ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    Text(viewModel.isRecording ? "Stop Recording" : "Record Audio")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(viewModel.isRecording ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            HStack {
                Button(action: viewModel.connectWebSocket) {
                    Text("Connect WebSocket")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(viewModel.isConnected ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(viewModel.isConnected)
                
                Button(action: viewModel.disconnectWebSocket) {
                    Text("Disconnect WebSocket")
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(viewModel.isConnected ? Color.red : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(!viewModel.isConnected)
            }
            .padding(.horizontal)
            
            // Optional: Display audio level as a progress bar
            if viewModel.isRecording {
                ProgressView(value: Double(viewModel.audioLevel))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .padding()
            }
        }
        .onAppear {
            // Optionally, connect WebSocket on appear
            // viewModel.connectWebSocket()
        }
        .onDisappear {
            viewModel.disconnectWebSocket()
        }
    }
}

struct GeminiChatView_Previews: PreviewProvider {
    static var previews: some View {
        GeminiChatView()
    }
}
