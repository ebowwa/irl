//
//  WebSocketManagerProtocol.swift
//  irl
//
//  Created by Elijah Arbee on 9/7/24.
//

import Foundation
import Combine

// MARK: - Protocols

protocol WebSocketManagerProtocol {
    var receivedDataPublisher: AnyPublisher<Data, Never> { get }
    func sendAudioData(_ data: Data)
}

protocol AudioStateProtocol: ObservableObject {
    var isRecording: Bool { get set }
    var isPlaying: Bool { get set }
    var recordingTime: TimeInterval { get set }
    var recordingProgress: Double { get set }
    var currentRecording: AudioRecording? { get set }
    var isPlaybackAvailable: Bool { get set }
    var errorMessage: String? { get set }
    var localRecordings: [AudioRecording] { get set }
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
    var formattedRecordingTime: String { get }

    func setupWebSocket(manager: WebSocketManagerProtocol)
    func toggleRecording()
    func stopRecording()
    func togglePlayback()
    func deleteRecording(_ recording: AudioRecording)
    func updateLocalRecordings()
    func formattedFileSize(bytes: Int64) -> String
}

// MARK: - WebSocketManager

class WebSocketManager: NSObject, WebSocketManagerProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private let receivedDataSubject = PassthroughSubject<Data, Never>()

    var receivedDataPublisher: AnyPublisher<Data, Never> {
        receivedDataSubject.eraseToAnyPublisher()
    }

    init(url: URL) {
        super.init()
        setupWebSocket(url: url)
    }

    private func setupWebSocket(url: URL) {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }

    func sendAudioData(_ data: Data) {
        webSocketTask?.send(.data(data)) { error in
            if let error = error {
                print("Error sending audio data: \(error.localizedDescription)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self?.receivedDataSubject.send(data)
                    }
                case .data(let data):
                    self?.receivedDataSubject.send(data)
                @unknown default:
                    print("Received unknown message type.")
                }
                self?.receiveMessage() // Continue listening for more messages
            case .failure(let error):
                print("Error receiving message: \(error.localizedDescription)")
                // Optionally, you might want to implement reconnection logic here
            }
        }
    }

    deinit {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}
