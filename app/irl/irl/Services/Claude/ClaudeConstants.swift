//
//  ClaudeConstants.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import Foundation

struct ClaudeConstants {
    struct API {
        static let baseURL = Constants.API.baseURL
        static let messagesEndpoint = Constants.API.Paths.claudeMessages
    }
    struct MessageRoles {
        static let user = "user"
        static let assistant = "assistant"
    }
    struct ContentTypes {
        static let text = "text"
    }
    struct DefaultParams {
        static let maxTokens = 1000
        static let model = "claude-3-haiku-20240307"
    }
    struct HTTPHeaders {
        static let contentTypeKey = "Content-Type"
        static let contentTypeValue = "application/json"
    }
}
