//
//  Constants.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import Foundation

struct Constants {
    static let baseDomain = "id.ngrok-free.app" // cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python index.py && ngrok http 8000
    
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
