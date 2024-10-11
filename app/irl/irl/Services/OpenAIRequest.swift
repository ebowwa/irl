import Foundation

// MARK: - ProxyAPIRequestConfig
struct ProxyAPIRequestConfig: Codable {
    let proxyApiUrl: String // not the request api but the proxy-to api url
    let apiKey: String? // usually null as passed from the server
    let modelType: String
    let systemInstruction: String?
    let userPrompt: String?
    let chatMessages: [[String: String]]?
    let responseTemperature: Float?
    let maxRequestTokens: Int?
    let maxCompletionTokens: Int?
    let tokenTopP: Float?
    let freqPenalty: Float?
    let presencePenalty: Float?
    let stopSequences: [String]?
    let numberOfResults: Int?
    let logitBiasMap: [String: Float]?
    let enableStream: Bool?
    let requestUserId: String?
    let additionalParams: [String: CodableAny]?
    
    enum CodingKeys: String, CodingKey {
        case proxyApiUrl = "api_url" // not the request api but the proxy-to api url
        case apiKey = "api_key"
        case modelType = "model"
        case systemInstruction = "system_prompt"
        case userPrompt = "prompt"
        case chatMessages = "messages"
        case responseTemperature = "temperature"
        case maxRequestTokens = "max_tokens"
        case maxCompletionTokens = "max_completion_tokens"
        case tokenTopP = "top_p"
        case freqPenalty = "frequency_penalty"
        case presencePenalty = "presence_penalty"
        case stopSequences = "stop"
        case numberOfResults = "n"
        case logitBiasMap = "logit_bias"
        case enableStream = "stream"
        case requestUserId = "user"
        case additionalParams = "extra_params"
    }
}

// MARK: - CodableAny
struct CodableAny: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([CodableAny].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: CodableAny].self) {
            var dict: [String: Any] = [:]
            for (key, codableAny) in dictValue {
                dict[key] = codableAny.value
            }
            value = dict
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode CodableAny")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            let codableArray = arrayValue.map { CodableAny($0) }
            try container.encode(codableArray)
        case let dictValue as [String: Any]:
            let codableDict = dictValue.mapValues { CodableAny($0) }
            try container.encode(codableDict)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Cannot encode CodableAny")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - ProxyAPIResponse
struct ProxyAPIResponse: Codable {
    let generatedResult: String
}

// MARK: - ProxyAPIError
enum ProxyAPIError: Error {
    case malformedURL
    case missingResponseData
    case parsingFailure
    case backendError(String)
}

// MARK: - TextGenerationService
struct TextGenerationService {
    
    // Shared instance for singleton pattern
    static let instance = TextGenerationService()
    
    private init() {}
    
    /// Sends a streaming request to the /LLM/generate-text/ endpoint with the given configuration.
    /// - Parameters:
    ///   - serverBaseUrl: The base URL of the backend server.
    ///   - config: The configuration for the Proxy API request.
    /// - Returns: An `AsyncThrowingStream<String, Error>` that yields chunks of the response.
    func sendTextStreamRequest(serverBaseUrl: String, config: ProxyAPIRequestConfig) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream<String, Error> { continuation in
            Task {
                do {
                    // Construct the full URL using the server's base URL
                    let urlString = serverBaseUrl + "/LLM/generate-text/"
                    print("Attempting to connect to URL: \(urlString)") // Debugging line
                    guard let url = URL(string: urlString) else {
                        continuation.finish(throwing: ProxyAPIError.malformedURL)
                        return
                    }
                    
                    // Prepare the URLRequest
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Encode the config to JSON
                    let encoder = JSONEncoder()
                    encoder.keyEncodingStrategy = .convertToSnakeCase
                    let jsonData = try encoder.encode(config)
                    request.httpBody = jsonData
                    
                    // Perform the request using AsyncBytes
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    // First, ensure response is HTTPURLResponse
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: ProxyAPIError.backendError("Invalid response from server."))
                        return
                    }
                    
                    // Then, check status code
                    guard (200...299).contains(httpResponse.statusCode) else {
                        // Read error data
                        var errorData = Data()
                        for try await byte in bytes {
                            errorData.append(byte)
                        }
                        if let errorResponse = try? JSONDecoder().decode([String: String].self, from: errorData),
                           let detail = errorResponse["detail"] {
                            continuation.finish(throwing: ProxyAPIError.backendError(detail))
                        } else {
                            continuation.finish(throwing: ProxyAPIError.backendError("Server returned status code \(httpResponse.statusCode)."))
                        }
                        return
                    }
                    
                    // Process streaming data
                    var buffer = Data()
                    for try await byte in bytes {
                        buffer.append(byte)
                        // Check for delimiter or specific chunking logic if necessary
                        if let chunk = String(data: buffer, encoding: .utf8) {
                            continuation.yield(chunk)
                            buffer.removeAll(keepingCapacity: true)
                        }
                    }
                    
                    // Finish the stream
                    continuation.finish()
                    
                } catch {
                    // Finish the stream with an error
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Sends a standard request to the /LLM/generate-text/ endpoint and returns the response.
    /// - Parameters:
    ///   - serverBaseUrl: The base URL of the backend server.
    ///   - config: The configuration for the Proxy API request.
    /// - Returns: A `ProxyAPIResponse` containing the result.
    func sendTextRequest(serverBaseUrl: String, config: ProxyAPIRequestConfig) async throws -> ProxyAPIResponse {
        // Construct the full URL using the server's base URL
        let urlString = serverBaseUrl + "/LLM/generate-text/"
        guard let url = URL(string: urlString) else {
            throw ProxyAPIError.malformedURL
        }
        
        // Prepare the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the config to JSON
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(config)
        request.httpBody = jsonData
        
        // Perform the network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProxyAPIError.backendError("Invalid response from server.")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Attempt to decode error message
            if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
               let detail = errorResponse["detail"] {
                throw ProxyAPIError.backendError(detail)
            }
            throw ProxyAPIError.backendError("Server returned status code \(httpResponse.statusCode).")
        }
        
        // Decode the response
        let decoder = JSONDecoder()
        let proxyAPIResponse = try decoder.decode(ProxyAPIResponse.self, from: data)
        
        return proxyAPIResponse
    }
}
