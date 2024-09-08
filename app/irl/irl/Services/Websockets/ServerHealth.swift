//
//  ServerHealth.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//

import Foundation
import Network

class ServerHealthManager: ObservableObject {
    @Published var isConnected = false
    @Published var lastPongReceived = "N/A"
    @Published var log = ""
    @Published var webSocketURL: String
    @Published var testConnectionURL: String

    private var webSocketTask: URLSessionWebSocketTask?

    init(webSocketPath: String = Constants.API.Paths.webSocketPing,
         testConnectionPath: String = Constants.API.Paths.testConnection) {
        self.webSocketURL = Constants.API.webSocketBaseURL + webSocketPath
        self.testConnectionURL = Constants.API.baseURL + testConnectionPath
    }

    func updateURLs(webSocketPath: String, testConnectionPath: String) {
        webSocketURL = Constants.API.webSocketBaseURL + webSocketPath
        testConnectionURL = Constants.API.baseURL + testConnectionPath
        appendToLog("URLs updated - WebSocket: \(webSocketURL), Test Connection: \(testConnectionURL)")
    }

    func connect() {
        guard let url = URL(string: webSocketURL) else {
            appendToLog("Invalid WebSocket URL")
            return
        }

        appendToLog("Attempting to connect to: \(url.absoluteString)")

        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)

        webSocketTask?.resume()

        receiveMessage()

        DispatchQueue.main.async {
            self.isConnected = true
            self.appendToLog("WebSocket connected")
            self.sendPing()
        }
    }

    func sendPing() {
        let message = URLSessionWebSocketTask.Message.string("PING")
        webSocketTask?.send(message) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.appendToLog("Error sending ping: \(error.localizedDescription)")
                } else {
                    self?.appendToLog("Sent Ping")
                }
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.appendToLog("Error receiving message: \(error.localizedDescription)")
                    self?.isConnected = false
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    DispatchQueue.main.async {
                        if text == "PONG" {
                            self?.lastPongReceived = Date().description
                            self?.appendToLog("Received Pong")
                        } else {
                            self?.appendToLog("Received text: \(text)")
                        }
                    }
                case .data(let data):
                    DispatchQueue.main.async {
                        self?.appendToLog("Received data: \(data.count) bytes")
                    }
                @unknown default:
                    break
                }

                self?.receiveMessage()
            }
        }
    }

    func testConnection() {
        guard let url = URL(string: testConnectionURL) else {
            appendToLog("Invalid Test Connection URL")
            return
        }

        appendToLog("Testing connection to: \(url.absoluteString)")

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.appendToLog("Connection test failed: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    self?.appendToLog("Connection test succeeded. Status code: \(httpResponse.statusCode)")
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        self?.appendToLog("Response body: \(body)")
                    }
                } else {
                    self?.appendToLog("Connection test completed with unknown response")
                }
            }
        }.resume()
    }

    private func appendToLog(_ message: String) {
        DispatchQueue.main.async {
            self.log += message + "\n"
            print(message)
        }
    }
}

