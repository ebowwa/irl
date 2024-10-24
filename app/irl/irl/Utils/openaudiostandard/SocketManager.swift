// WebSocketManager.swift
import Foundation


public class WebSocketManager: WebSocketManagerProtocol {
    
    public private(set) var isConnected: Bool = false
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    private let session: URLSession
    
    // Initialization with WebSocket URL
    public init(url: URL) {
        self.url = url
        self.session = URLSession(configuration: .default)
    }
    
    // Connect to WebSocket
    public func connect() {
        guard !isConnected else { return }
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        listen()
        print("WebSocket connected to \(url)")
    }
    
    // Disconnect from WebSocket
    public func disconnect() {
        guard isConnected else { return }
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        print("WebSocket disconnected from \(url)")
    }
    
    // Send Audio Data
    public func sendAudioData(_ data: Data) {
        guard isConnected else { return }
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error: \(error.localizedDescription)")
            }
        }
    }
    
    // Listen for incoming messages (if needed)
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self, self.isConnected else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    // Handle incoming data if necessary
                    print("WebSocket received data: \(data)")
                case .string(let text):
                    // Handle incoming text if necessary
                    print("WebSocket received text: \(text)")
                @unknown default:
                    print("WebSocket received unknown message type.")
                }
                self.listen() // Continue listening
            case .failure(let error):
                print("WebSocket receive error: \(error.localizedDescription)")
                self.isConnected = false
            }
        }
    }
}

