import Combine
import Foundation

// MARK: - AnyCodable

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value.map { $0.value }
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let value as Bool:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as String:
            try container.encode(value)
        case let value as [Any]:
            try container.encode(value.map { AnyCodable($0) })
        case let value as [String: Any]:
            try container.encode(value.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

// MARK: - Error Definitions

enum SDXLServiceError: LocalizedError {
    case invalidURL
    case invalidRequestBody
    case serverError(statusCode: Int, detail: String?)
    case invalidResponse
    case decodingError(description: String)
    case requestFailed(description: String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL."
        case .invalidRequestBody:
            return "Failed to encode the request body."
        case .serverError(let statusCode, let detail):
            return detail != nil ? "Server returned an error with status code \(statusCode): \(detail!)" : "Server returned an error with status code \(statusCode)."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .decodingError(let description):
            return "Failed to decode the response: \(description)"
        case .requestFailed(let description):
            return "The image generation request failed: \(description)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

// MARK: - Request and Response Models

struct SDXLImageGenerationRequest: Codable {
    let prompt: String
    let negative_prompt: String?
    let image_size: String
    let num_inference_steps: Int
    let seed: Int?
    let guidance_scale: Double
    let num_images: Int
    let loras: [[String: AnyCodable]]?
    let embeddings: [[String: AnyCodable]]?
    let enable_safety_checker: Bool
    let safety_checker_version: String?
    let expand_prompt: Bool?
    let format: String
}

struct SDXLImageGenerationResponse: Decodable {
    let request_id: String
}

struct SDXLRequestStatusResponse: Decodable {
    let request_id: String?
    let status: String?
    let eta: Double?
    let detail: String?
    let response_url: String?
}

struct GeneratedSDXLImage: Decodable {
    let url: String
    let width: Int
    let height: Int
    let content_type: String
}

struct ImageResultResponse: Decodable {
    let seed: UInt64?
    let images: [GeneratedSDXLImage]
    let prompt: String
    let inference_time: Double?
    let has_nsfw_concepts: [Bool]
}

// MARK: - SDXLImageGenerationService

class SDXLImageGenerationService: ObservableObject {
    @Published var isGeneratingImage = false
    @Published var generatedImageUrl: String?
    @Published var generationErrorMessage: String?
    @Published var generationLogs: String = ""

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Methods

    func generateImage(
        fromPrompt prompt: String,
        imageSize: String = "square_hd",
        numImages: Int = 1,
        outputFormat: String = "jpeg",
        guidanceScale: Double = 7.5,
        numInferenceSteps: Int = 25,
        enableSafetyChecker: Bool = true,
        negativePrompt: String? = nil,
        seed: Int? = nil,
        loras: [[String: Any]]? = nil,
        embeddings: [[String: Any]]? = nil,
        safetyCheckerVersion: String? = nil,
        expandPrompt: Bool? = nil
    ) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isGeneratingImage = true
                self.generationLogs = "Submitting image generation request..."
                self.generatedImageUrl = nil
                self.generationErrorMessage = nil
            }

            // Step 1: Submit generation request
            self.submitGenerationRequest(
                prompt: prompt,
                negativePrompt: negativePrompt,
                imageSize: imageSize,
                numImages: numImages,
                outputFormat: outputFormat,
                guidanceScale: guidanceScale,
                numInferenceSteps: numInferenceSteps,
                enableSafetyChecker: enableSafetyChecker,
                seed: seed,
                loras: loras,
                embeddings: embeddings,
                safetyCheckerVersion: safetyCheckerVersion,
                expandPrompt: expandPrompt
            )
            .flatMap { response -> AnyPublisher<SDXLRequestStatusResponse, Error> in
                // Step 2: Check status
                self.updateLog("Generation request submitted. Request ID: \(response.request_id)")
                return self.checkRequestStatusWithDelays(requestId: response.request_id)
            }
            .flatMap { statusResponse -> AnyPublisher<ImageResultResponse, Error> in
                // Step 3: Fetch result from backend's /sdxl/result/{request_id}
                self.updateLog("Generation complete. Fetching result from backend...")
                guard let requestId = statusResponse.request_id else {
                    let errorDetail = statusResponse.detail ?? "Missing request_id in status response."
                    self.updateLog("Error: \(errorDetail)")
                    return Fail(error: SDXLServiceError.requestFailed(description: errorDetail)).eraseToAnyPublisher()
                }
                return self.fetchImageResult(requestId: requestId)
            }
            .sink { [weak self] completion in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch completion {
                    case .failure(let error):
                        self.generationErrorMessage = "Image generation failed: \(error.localizedDescription)"
                        self.updateLog("Error: \(error.localizedDescription)")
                    case .finished:
                        self.updateLog("Image generation process completed.")
                    }
                    self.isGeneratingImage = false
                }
            } receiveValue: { [weak self] imageResult in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.updateLog("Received Image Result: \(imageResult)")
                    if let firstImage = imageResult.images.first {
                        self.generatedImageUrl = firstImage.url
                        self.updateLog("Image URL set to: \(firstImage.url)")
                    } else {
                        self.updateLog("No images were generated.")
                        self.generationErrorMessage = "No images were generated."
                    }

                    if let seed = imageResult.seed {
                        self.updateLog("Image generated with seed: \(seed)")
                    } else {
                        self.updateLog("Image generated without a specific seed.")
                    }
                }
            }
            .store(in: &self.cancellables)
        }
    }

    // MARK: - Private Helper Methods

    private func convertToAnyCodable(_ array: [[String: Any]]?) -> [[String: AnyCodable]]? {
        guard let array = array else { return nil }
        return array.map { dict in
            dict.mapValues { AnyCodable($0) }
        }
    }

    private func submitGenerationRequest(
        prompt: String,
        negativePrompt: String?,
        imageSize: String,
        numImages: Int,
        outputFormat: String,
        guidanceScale: Double,
        numInferenceSteps: Int,
        enableSafetyChecker: Bool,
        seed: Int?,
        loras: [[String: Any]]?,
        embeddings: [[String: Any]]?,
        safetyCheckerVersion: String?,
        expandPrompt: Bool?
    ) -> AnyPublisher<SDXLImageGenerationResponse, Error> {
        guard let requestURL = URL(string: Constants.API.baseURL + Constants.API.Paths.sdxlGenerate) else {
            return Fail(error: SDXLServiceError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization") // If authentication is required

        let anyCodableLoras = convertToAnyCodable(loras)
        let anyCodableEmbeddings = convertToAnyCodable(embeddings)

        let body = SDXLImageGenerationRequest(
            prompt: prompt,
            negative_prompt: negativePrompt,
            image_size: imageSize,
            num_inference_steps: numInferenceSteps,
            seed: seed,
            guidance_scale: guidanceScale,
            num_images: numImages,
            loras: anyCodableLoras,
            embeddings: anyCodableEmbeddings,
            enable_safety_checker: enableSafetyChecker,
            safety_checker_version: safetyCheckerVersion,
            expand_prompt: expandPrompt,
            format: outputFormat
        )

        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        } catch {
            return Fail(error: SDXLServiceError.invalidRequestBody).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw SDXLServiceError.invalidResponse
                }

                self.updateLog("Response status code: \(httpResponse.statusCode)")
                self.updateLog("Raw response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response data")")

                guard (200...299).contains(httpResponse.statusCode) else {
                    // Attempt to extract error detail if available
                    if let errorDetail = try? JSONDecoder().decode([String: String].self, from: data)["detail"] {
                        throw SDXLServiceError.serverError(statusCode: httpResponse.statusCode, detail: errorDetail)
                    } else {
                        throw SDXLServiceError.serverError(statusCode: httpResponse.statusCode, detail: nil)
                    }
                }

                return data
            }
            .decode(type: SDXLImageGenerationResponse.self, decoder: JSONDecoder())
            .mapError { error -> Error in
                if let decodingError = error as? DecodingError {
                    self.updateLog("Decoding error: \(decodingError)")
                    return SDXLServiceError.decodingError(description: decodingError.localizedDescription)
                } else if let sdxlError = error as? SDXLServiceError {
                    return sdxlError
                }
                return SDXLServiceError.unknown
            }
            .eraseToAnyPublisher()
    }

    private func checkRequestStatusWithDelays(requestId: String) -> AnyPublisher<SDXLRequestStatusResponse, Error> {
        // Construct the URL carefully to avoid extra slashes
        let baseURLString = Constants.API.baseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        let statusPath = Constants.API.Paths.sdxlStatus.trimmingCharacters(in: .init(charactersIn: "/"))
        let urlString = "\(baseURLString)/\(statusPath)/\(requestId)"

        guard let statusURL = URL(string: urlString) else {
            self.updateLog("Invalid URL: \(urlString)")
            return Fail(error: SDXLServiceError.invalidURL).eraseToAnyPublisher()
        }

        self.updateLog("Checking status at URL: \(statusURL.absoluteString)")

        var request = URLRequest(url: statusURL)
        request.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw SDXLServiceError.invalidResponse
                }

                self.updateLog("Status check response code: \(httpResponse.statusCode)")
                self.updateLog("Status check raw data: \(String(data: data, encoding: .utf8) ?? "Unable to decode status data")")

                // Accept 200 and 202 status codes
                guard (200...202).contains(httpResponse.statusCode) else {
                    // Attempt to extract error detail if available
                    if let errorDetail = try? JSONDecoder().decode([String: String].self, from: data)["detail"] {
                        throw SDXLServiceError.serverError(statusCode: httpResponse.statusCode, detail: errorDetail)
                    } else {
                        throw SDXLServiceError.serverError(statusCode: httpResponse.statusCode, detail: nil)
                    }
                }

                return data
            }
            .decode(type: SDXLRequestStatusResponse.self, decoder: JSONDecoder())
            .mapError { error -> Error in
                if let decodingError = error as? DecodingError {
                    self.updateLog("Decoding error: \(decodingError)")
                    return SDXLServiceError.decodingError(description: "Failed to decode status response: \(decodingError.localizedDescription)")
                } else if let sdxlError = error as? SDXLServiceError {
                    return sdxlError
                }
                return SDXLServiceError.unknown
            }
            .flatMap { statusResponse -> AnyPublisher<SDXLRequestStatusResponse, Error> in
                self.updateLog("Received status for request ID \(statusResponse.request_id ?? "N/A"): \(statusResponse.status ?? "No status provided")")
                if let detail = statusResponse.detail {
                    self.updateLog("Status details: \(detail)")
                }

                guard let status = statusResponse.status else {
                    let errorDetail = statusResponse.detail ?? "Missing status in status response."
                    return Fail(error: SDXLServiceError.requestFailed(description: errorDetail)).eraseToAnyPublisher()
                }

                switch status.lowercased() {
                case "completed":
                    // If completed, return the status to proceed to fetch the image
                    return Just(statusResponse).setFailureType(to: Error.self).eraseToAnyPublisher()
                case "processing", "pending", "in_progress":
                    // Determine delay based on ETA or use a default value
                    let delaySeconds: Double
                    if let eta = statusResponse.eta, eta > 0 {
                        delaySeconds = eta
                    } else {
                        delaySeconds = 2.0 // Default delay
                    }
                    self.updateLog("Request is still \(status). Checking again in \(delaySeconds) seconds.")
                    return self.checkRequestStatusWithDelays(requestId: requestId)
                        .delay(for: .seconds(delaySeconds), scheduler: DispatchQueue.global())
                        .eraseToAnyPublisher()
                case "failed":
                    // If failed, return an error
                    let errorMessage = statusResponse.detail ?? "Image generation failed without specific error details."
                    return Fail(error: SDXLServiceError.requestFailed(description: errorMessage)).eraseToAnyPublisher()
                default:
                    return Fail(error: SDXLServiceError.unknown).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    private func fetchImageResult(requestId: String) -> AnyPublisher<ImageResultResponse, Error> {
        // Construct the URL to your backend's /sdxl/result/{request_id} endpoint
        let baseURLString = Constants.API.baseURL.trimmingCharacters(in: .init(charactersIn: "/"))
        let resultPath = Constants.API.Paths.sdxlResult.trimmingCharacters(in: .init(charactersIn: "/"))
        let urlString = "\(baseURLString)/\(resultPath)/\(requestId)"

        guard let resultURL = URL(string: urlString) else {
            self.updateLog("Invalid Result URL: \(urlString)")
            return Fail(error: SDXLServiceError.invalidURL).eraseToAnyPublisher()
        }

        self.updateLog("Fetching image result from URL: \(resultURL.absoluteString)")

        var request = URLRequest(url: resultURL)
        request.httpMethod = "GET"

        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw SDXLServiceError.invalidResponse
                }

                self.updateLog("Result fetch response code: \(httpResponse.statusCode)")
                self.updateLog("Result fetch raw data: \(String(data: data, encoding: .utf8) ?? "Unable to decode result data")")

                guard (200...299).contains(httpResponse.statusCode) else {
                    // Attempt to extract error detail if available
                    if let errorDetail = try? JSONDecoder().decode([String: String].self, from: data)["detail"] {
                        throw SDXLServiceError.serverError(statusCode: httpResponse.statusCode, detail: errorDetail)
                    } else {
                        throw SDXLServiceError.serverError(statusCode: httpResponse.statusCode, detail: nil)
                    }
                }

                return data
            }
            .decode(type: ImageResultResponse.self, decoder: JSONDecoder())
            .mapError { error -> Error in
                if let decodingError = error as? DecodingError {
                    self.updateLog("Result decoding error: \(decodingError)")
                    return SDXLServiceError.decodingError(description: decodingError.localizedDescription)
                } else if let sdxlError = error as? SDXLServiceError {
                    return sdxlError
                }
                return SDXLServiceError.unknown
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Logging

    private func updateLog(_ message: String) {
        DispatchQueue.main.async {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            self.generationLogs += "\n[\(timestamp)] \(message)"
        }
    }
}
