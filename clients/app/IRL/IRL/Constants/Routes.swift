//
//  Routes.swift
//
// irl
// Created by Elijah Arbee on 9/2/24.

import Foundation

struct ConstantRoutes {
    struct API {
        struct Paths {
            static let webSocketPing = "/ws/ping"
            static let testConnection = "/"
            static let upload = "/upload"
            static let whisperTTS = "/ws/WhisperTTS"
            static let humeWebSocket = "/ws/hume" // @deprecated need to add the new route it's not a websocket
            static let claudeMessages = "/v3/claude/messages" // TODO: add OpenRouter
            static let embedding = "/embeddings" // Can probably cleaner add the small & large embedding endpoints to this constants definition
            // SDXL API Paths
            static let sdxlGenerate = "/api/sdxl/generate"
            static let sdxlStatus = "/api/sdxl/status/"
            static let sdxlResult = "/api/sdxl/result/"
            
            // ** Flux Image Generation API Paths **
            static let imageGenerationSubmit = "/api/FLUXLORAFAL/submit"
            static let imageGenerationStatus = "/api/FLUXLORAFAL/status/"
            static let imageGenerationResult = "/api/FLUXLORAFAL/result/"
            
            // **OPENAI LIB** OLLAMA Integrated
            static let generateText = "/LLM/generate-text/"

        }
    }
}
