import SwiftUI
import Combine
import AVFoundation
import WebKit

class GeminiChatViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var chatLog: [String] = []
    @Published var messageInput: String = ""
    @Published var isConnected: Bool = false
    @Published var isRecording: Bool = false
    var audioRecorder: AVAudioRecorder?
    var audioChunks: [Data] = []
    var webSocketTask: URLSessionWebSocketTask?
    
    // WebSocket Connect
    func connectWebSocket() {
        guard let url = URL(string: "wss://e2ee-50-247-127-70.ngrok-free.app/api/gemini/ws/chat") else { return }
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        appendMessage(sender: "System", message: "Connected to Gemini Chat.")
        receiveMessage()
    }
    
    // WebSocket Disconnect
    func disconnectWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        appendMessage(sender: "System", message: "Disconnected from Gemini Chat.")
    }
    
    // Append message to chat log
    func appendMessage(sender: String, message: String) {
        chatLog.append("\(sender): \(message)")
    }
    
    // WebSocket Send Message
    func sendMessage() {
        guard !messageInput.isEmpty, let webSocketTask = webSocketTask else { return }
        let message = URLSessionWebSocketTask.Message.string("{\"role\":\"user\",\"text\":\"\(messageInput)\",\"type\":\"text\"}")
        webSocketTask.send(message) { error in
            if let error = error {
                self.appendMessage(sender: "Error", message: "\(error.localizedDescription)")
            } else {
                self.appendMessage(sender: "You", message: self.messageInput)
            }
        }
        messageInput = ""
    }
    
    // WebSocket Receive Message
    func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        if let data = text.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                           let response = json["response"] {
                            self.appendMessage(sender: "Gemini", message: response)
                        }
                    }
                case .data:
                    break // Handle data if necessary
                @unknown default:
                    break
                }
                self.receiveMessage() // Continue to listen
            case .failure(let error):
                self.appendMessage(sender: "Error", message: "\(error.localizedDescription)")
            }
        }
    }
    
    // Start Recording Audio
    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.wav")
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            appendMessage(sender: "System", message: "Recording audio...")
        } catch {
            appendMessage(sender: "Error", message: "Failed to start recording.")
        }
    }
    
    // Stop Recording and Send Audio
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        if let audioData = try? Data(contentsOf: getDocumentsDirectory().appendingPathComponent("recording.wav")), let webSocketTask = webSocketTask {
            let base64Audio = audioData.base64EncodedString()
            let message = URLSessionWebSocketTask.Message.string("{\"role\":\"user\",\"audio\":\"\(base64Audio)\",\"type\":\"audio\"}")
            webSocketTask.send(message) { error in
                if let error = error {
                    self.appendMessage(sender: "Error", message: "\(error.localizedDescription)")
                } else {
                    self.appendMessage(sender: "System", message: "Audio message sent.")
                }
            }
        }
    }
    
    // Get Documents Directory
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // AVAudioRecorderDelegate Method
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            appendMessage(sender: "System", message: "Finished recording audio.")
        } else {
            appendMessage(sender: "Error", message: "Recording was not successful.")
        }
    }
}

struct GeminiChatView: View {
    @StateObject private var viewModel = GeminiChatViewModel()
    
    var body: some View {
        VStack {
            Text("omi")
                .font(.largeTitle)
                .padding()
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(viewModel.chatLog, id: \ .self) { message in
                        Text(message)
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
            }
            .frame(height: 300)
            .border(Color.gray, width: 1)
            .padding()
            
            TextField("Enter your message here...", text: $viewModel.messageInput, onCommit: viewModel.sendMessage)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .disabled(!viewModel.isConnected)
            
            HStack {
                Button(action: viewModel.sendMessage) {
                    Text("Send Text")
                }
                .padding()
                .disabled(!viewModel.isConnected)
                
                Button(action: viewModel.startRecording) {
                    Text("Record Audio")
                }
                .padding()
                .disabled(!viewModel.isConnected || viewModel.isRecording)
                
                Button(action: viewModel.stopRecording) {
                    Text("Stop Recording")
                }
                .padding()
                .disabled(!viewModel.isRecording)
            }
            
            HStack {
                Button(action: viewModel.connectWebSocket) {
                    Text("Connect WebSocket")
                }
                .padding()
                .disabled(viewModel.isConnected)
                
                Button(action: viewModel.disconnectWebSocket) {
                    Text("Disconnect WebSocket")
                }
                .padding()
                .disabled(!viewModel.isConnected)
            }
        }
        .onDisappear {
            viewModel.disconnectWebSocket()
        }
    }
}
