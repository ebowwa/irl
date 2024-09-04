//
//  Constants.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import Foundation

struct Constants {
    static let baseDomain = "9fd4-73-15-186-2.ngrok-free.app"
    
    struct API {
        static let baseURL = "https://\(Constants.baseDomain)"
        static let webSocketBaseURL = "wss://\(Constants.baseDomain)"
        
        struct Paths {
            static let webSocketPing = "/ws/ping"
            static let testConnection = "/"
            static let upload = "/upload"
            static let whisperTTS = "/ws/WhisperTTS"
            static let humeWebSocket = "/ws/hume"
            static let claudeMessages = "/api/v1/messages"  // New path for Claude API
        }
    }
}
