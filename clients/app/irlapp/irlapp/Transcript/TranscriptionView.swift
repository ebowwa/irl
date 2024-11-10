//
//  TranscriptionView.swift
//   CaringMind
//
//  Created by Elijah Arbee on 11/9/24.
//
import Foundation
import SwiftUI
import AVFoundation
import Speech

// MARK: - WebSocket Protocol
protocol WebSocketDelegate: AnyObject {
    func didReceiveTranscription(_ transcription: [TranscriptionSegment])
    func didEncounterError(_ error: Error)
}

// MARK: - WebSocket Manager
class WebSocketManager: NSObject {
    private var webSocket: URLSessionWebSocketTask?
    weak var delegate: WebSocketDelegate?
    
    func connect() {
        let session = URLSession(configuration: .default)
        let url = URL(string: "ws://127.0.0.1:9090/transcribe/ws")!
        webSocket = session.webSocketTask(with: url)
        webSocket?.resume()
        receiveMessage()
    }
    
    func send(audioData: Data) {
        let message = URLSessionWebSocketTask.Message.data(audioData)
        webSocket?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self?.handleReceivedData(data)
                case .string(let string):
                    self?.handleReceivedString(string)
                @unknown default:
                    break
                }
                self?.receiveMessage() // Continue receiving
            case .failure(let error):
                self?.delegate?.didEncounterError(error)
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(TranscriptionResponse.self, from: data)
            DispatchQueue.main.async {
                self.delegate?.didReceiveTranscription(response.transcriptions)
            }
        } catch {
            delegate?.didEncounterError(error)
        }
    }
    
    private func handleReceivedString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        handleReceivedData(data)
    }
}

// MARK: - View Models
class EnhancedTranscriptionViewModel: ObservableObject, WebSocketDelegate {
    @Published var transcriptionManager: TranscriptionManager
    @Published var segments: [TranscriptionSegment] = []
    @Published var error: String?
    @Published var isProcessing = false
    
    private let webSocketManager = WebSocketManager()
    private var audioExporter: AudioExporter?
    
    init(transcriptionManager: TranscriptionManager = TranscriptionManager()) {
        self.transcriptionManager = transcriptionManager
        self.webSocketManager.delegate = self
        setupPeriodicExport()
    }
    
    private func setupPeriodicExport() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.exportAndSendAudio()
        }
    }
    
    func exportAndSendAudio() {
        guard transcriptionManager.isRecording else { return }
        isProcessing = true
        
        audioExporter?.export { [weak self] result in
            switch result {
            case .success(let audioData):
                self?.webSocketManager.send(audioData: audioData)
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.error = error.localizedDescription
                }
            }
            DispatchQueue.main.async {
                self?.isProcessing = false
            }
        }
    }
    
    // WebSocketDelegate methods
    func didReceiveTranscription(_ transcription: [TranscriptionSegment]) {
        DispatchQueue.main.async {
            self.segments = transcription
        }
    }
    
    func didEncounterError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Views
struct EnhancedTranscriptionView: View {
    @StateObject private var viewModel: EnhancedTranscriptionViewModel
    @Environment(\.colorScheme) var colorScheme
    
    init(viewModel: EnhancedTranscriptionViewModel = EnhancedTranscriptionViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Audio Visualization
                AudioLevelView(level: viewModel.transcriptionManager.audioLevel)
                    .frame(height: 60)
                    .padding()
                
                // Live Transcription
                if !viewModel.transcriptionManager.transcribedText.isEmpty {
                    LiveTranscriptionView(text: viewModel.transcriptionManager.transcribedText)
                }
                
                // Segmented Transcripts
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.segments) { segment in
                                TranscriptionSegmentView(segment: segment)
                                    .id(segment.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.segments.count) { _ in
                        if let lastId = viewModel.segments.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Controls
                ControlsView(viewModel: viewModel)
            }
            .navigationTitle("Enhanced Transcription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Transcription") {
                            // Implement export functionality
                        }
                        Button("Clear All", role: .destructive) {
                            viewModel.transcriptionManager.clearTranscription()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .overlay {
                if viewModel.isProcessing {
                    ProcessingOverlay()
                }
            }
        }
    }
}

// Supporting Views...
struct AudioLevelView: View {
    let level: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .green, .yellow, .red]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: geometry.size.width * CGFloat(level))
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

struct LiveTranscriptionView: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.body)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
    }
}

struct TranscriptionSegmentView: View {
    let segment: TranscriptionSegment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(segment.speaker)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1fs", segment.timestamp.start))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(segment.transcription)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }
}

struct ControlsView: View {
    @ObservedObject var viewModel: EnhancedTranscriptionViewModel
    
    var body: some View {
        HStack(spacing: 30) {
            Spacer()
            
            Button(action: {
                if viewModel.transcriptionManager.isRecording {
                    viewModel.transcriptionManager.stopRecording()
                } else {
                    viewModel.transcriptionManager.startRecording()
                }
            }) {
                Circle()
                    .fill(viewModel.transcriptionManager.isRecording ? Color.red : Color.blue)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: viewModel.transcriptionManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 2)
    }
}

struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Processing Audio...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.8))
            .cornerRadius(16)
        }
    }
}
