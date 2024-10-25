//
//  HumeView.swift
//  irl
//
//  Created by Elijah Arbee on 9/1/24.
//
import SwiftUI
import AVFoundation

struct HumeView: View {
    @StateObject private var viewModel = HumeViewModel()
    
    var body: some View {
        VStack {
            Text("Hume API Integration")
                .font(.title)
            
            Text("Status: \(viewModel.connectionStatus)")
                .padding()
            
            Button(action: {
                viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
            }) {
                Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                    .padding()
                    .background(viewModel.isRecording ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(viewModel.connectionStatus != "Connected")
            
            ScrollView {
                Text(viewModel.humeResults)
                    .padding()
            }
        }
        .padding()
    }
}

class HumeViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var humeResults = ""
    @Published var connectionStatus = "Disconnected"
    
    private var audioRecorder: AVAudioRecorder?
    private var webSocketTask: URLSessionWebSocketTask?
    private let serverURL = URL(string: Constants.API.webSocketBaseURL + ConstantRoutes.API.Paths.humeWebSocket)!
    
    init() {
        connectWebSocket()
    }
    
    private func connectWebSocket() {
        webSocketTask = URLSession.shared.webSocketTask(with: serverURL)
        webSocketTask?.resume()
        
        receiveMessages()
        connectionStatus = "Connected"
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        self?.humeResults = text
                    }
                case .data:
                    break
                @unknown default:
                    break
                }
                self?.receiveMessages()
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.connectionStatus = "Disconnected"
            }
        }
    }
    
    func startRecording() {
        print("Starting recording")
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            
            // Start sending audio data to the server
            sendAudioData()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        print("Stopping recording")
        audioRecorder?.stop()
        isRecording = false
    }
    
    private func sendAudioData() {
        guard let audioRecorder = audioRecorder else { return }
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, self.isRecording else {
                timer.invalidate()
                return
            }
            
            if let audioData = try? Data(contentsOf: audioRecorder.url) {
                let base64Audio = audioData.base64EncodedString()
                print("Sending audio data, length: \(base64Audio.count)")
                self.webSocketTask?.send(.string(base64Audio)) { error in
                    if let error = error {
                        print("Error sending message: \(error)")
                    } else {
                        print("Audio data sent successfully")
                    }
                }
            }
        }
    }
}
