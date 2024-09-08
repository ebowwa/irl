//
//  WebsocketHandler.swift
//  irl
//
//  Created by Elijah Arbee on 9/8/24.
//
import Foundation

class WebSocketHandler {
    static func connectWebSocket(audioUrl: String, task: TaskEnum, language: LanguageEnum, completion: @escaping (Result<WhisperOutput, Error>) -> Void) {
        guard let url = URL(string: Constants.API.webSocketBaseURL + Constants.API.Paths.whisperTTS) else { return }
        
        let urlSession = URLSession(configuration: .default)
        let webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask.resume()
        
        sendMessage(webSocketTask: webSocketTask, audioUrl: audioUrl, task: task, language: language)
        receiveMessage(webSocketTask: webSocketTask, completion: completion)
    }
    
    private static func sendMessage(webSocketTask: URLSessionWebSocketTask, audioUrl: String, task: TaskEnum, language: LanguageEnum) {
        let message = WhisperInput(audio_url: audioUrl, task: task, language: language)
        guard let encodedMessage = try? JSONEncoder().encode(message),
              let messageString = String(data: encodedMessage, encoding: .utf8) else { return }
        
        webSocketTask.send(.string(messageString)) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }
    
    private static func receiveMessage(webSocketTask: URLSessionWebSocketTask, completion: @escaping (Result<WhisperOutput, Error>) -> Void) {
        webSocketTask.receive { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let decodedMessage = try? JSONDecoder().decode(WhisperOutput.self, from: data) {
                        completion(.success(decodedMessage))
                    }
                case .data(_):
                    break
                @unknown default:
                    break
                }
                receiveMessage(webSocketTask: webSocketTask, completion: completion)
            }
        }
    }
}
