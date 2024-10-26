// File: FluxImageGenerationService.swift

import Foundation
import SwiftUI
import Combine
import UIKit

// MARK: - Data Models

// Response model for submission
struct SubmitResponse: Codable {
    let request_id: String
    let status: String
}

// Response model for status check
struct StatusResponse: Codable {
    let request_id: String
    let status: String
    let logs: [String]?
}

// Response model for fetching the final result
struct ResultResponse: Codable {
    let request_id: String
    let status: String
    let images: [GeneratedImage]
    let prompt: String?
    let timings: [String: Double]?
    let has_nsfw_concepts: [Bool]?
}

struct GeneratedImage: Codable, Identifiable {
    let id = UUID()
    let url: String
    let content_type: String?
    let width: Int?
    let height: Int?
}

// Request body model
struct ImageGenerationRequestBody: Codable {
    let prompt: String
    let image_size: String
    let num_inference_steps: Int
    let guidance_scale: Double
    let num_images: Int
    let enable_safety_checker: Bool
    let output_format: String
}

// Error response model
struct ErrorResponse: Codable {
    let detail: String
}

// MARK: - Service

@MainActor
class FluxImageGenerationService: ObservableObject {
    // Published Properties
    @Published var generationLogs: String = ""
    @Published var generatedImageUrl: String? = nil
    @Published var generatedImage: UIImage? = nil
    @Published var isGeneratingImage: Bool = false
    @Published var generationErrorMessage: String? = nil

    // Private Properties
    private let baseURL: String

    // Initializer
    init() {
        self.baseURL = Constants.API.baseURL
    }

    // Generate Image Method
    func generateImage(
        fromPrompt prompt: String,
        imageSize: String = "landscape_4_3",
        numImages: Int = 1,
        outputFormat: String = "jpeg",
        guidanceScale: Double = 3.5,
        numInferenceSteps: Int = 28,
        enableSafetyChecker: Bool = true
    ) {
        // Reset State
        isGeneratingImage = true
        generatedImageUrl = nil
        generatedImage = nil
        generationLogs = ""
        generationErrorMessage = nil

        Task {
            await generateImageAsync(
                fromPrompt: prompt,
                imageSize: imageSize,
                numImages: numImages,
                outputFormat: outputFormat,
                guidanceScale: guidanceScale,
                numInferenceSteps: numInferenceSteps,
                enableSafetyChecker: enableSafetyChecker
            )
        }
    }

    // Async Function to Handle the Image Generation Flow
    private func generateImageAsync(
        fromPrompt prompt: String,
        imageSize: String,
        numImages: Int,
        outputFormat: String,
        guidanceScale: Double,
        numInferenceSteps: Int,
        enableSafetyChecker: Bool
    ) async {
        // Create the request body using Codable
        let requestBody = ImageGenerationRequestBody(
            prompt: prompt,
            image_size: imageSize,
            num_inference_steps: numInferenceSteps,
            guidance_scale: guidanceScale,
            num_images: numImages,
            enable_safety_checker: enableSafetyChecker,
            output_format: outputFormat
        )

        do {
            // Step 1: Submit the Image Generation Request
            let submitResponse = try await submitImageGenerationRequest(requestBody: requestBody)
            print("Request submitted with ID: \(submitResponse.request_id)")
            self.generationLogs += "Request submitted with ID: \(submitResponse.request_id)\n"

            var status = submitResponse.status
            let requestId = submitResponse.request_id

            // Step 2: Poll for Status Until Completion or Failure
            while status.lowercased() != "completed" && status.lowercased() != "failed" {
                let statusResponse = try await checkRequestStatus(requestId: requestId)
                status = statusResponse.status
                print("Current status: \(status)")
                self.generationLogs += "Current status: \(status)\n"

                if let logs = statusResponse.logs {
                    appendLogs(logs)
                }

                if status.lowercased() == "failed" {
                    throw NSError(domain: "ImageGeneration", code: -1, userInfo: [NSLocalizedDescriptionKey: "Image generation failed"])
                }

                if status.lowercased() == "completed" {
                    // Once completed, fetch the result
                    let result = try await fetchResult(requestId: requestId)
                    if let firstImage = result.images.first {
                        self.generatedImageUrl = firstImage.url
                        self.generationLogs += "Image generated successfully.\n"

                        // Step 4: Download the Image
                        try await downloadImage(from: firstImage.url)
                    } else {
                        self.generationErrorMessage = "No images found in the generation response."
                    }
                } else {
                    // Wait before polling again
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            self.generationErrorMessage = "Error: \(error.localizedDescription)"
        }
        self.isGeneratingImage = false
    }

    // Step 1: Submit Image Generation Request
    private func submitImageGenerationRequest(requestBody: ImageGenerationRequestBody) async throws -> SubmitResponse {
        guard let url = URL(string: Constants.API.baseURL + ConstantRoutes.API.Paths.imageGenerationSubmit) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let requestData = try encoder.encode(requestBody)
        request.httpBody = requestData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let message = errorResponse?.detail ?? "Unknown error"
            throw NSError(domain: "ImageGeneration", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let submitResponse = try JSONDecoder().decode(SubmitResponse.self, from: data)
        return submitResponse
    }

    // Step 2: Check Request Status
    private func checkRequestStatus(requestId: String) async throws -> StatusResponse {
        // Construct the URL using Constants
        let statusPath = ConstantRoutes.API.Paths.imageGenerationStatus + requestId
        guard let url = URL(string: baseURL + statusPath) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let message = errorResponse?.detail ?? "Unknown error"
            throw NSError(domain: "ImageGeneration", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let statusResponse = try JSONDecoder().decode(StatusResponse.self, from: data)
        return statusResponse
    }

    // Step 3: Fetch the Result
    private func fetchResult(requestId: String) async throws -> ResultResponse {
        // Construct the URL using Constants
        let resultPath = ConstantRoutes.API.Paths.imageGenerationResult + requestId
        guard let url = URL(string: baseURL + resultPath) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let message = errorResponse?.detail ?? "Unknown error"
            throw NSError(domain: "ImageGeneration", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }

        let resultResponse = try JSONDecoder().decode(ResultResponse.self, from: data)
        return resultResponse
    }

    // Step 4: Download the Image
    private func downloadImage(from urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        guard let uiImage = UIImage(data: data) else {
            throw NSError(domain: "ImageGeneration", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to UIImage"])
        }

        // Assign the downloaded image to the published property
        self.generatedImage = uiImage
    }

    // Helper Method to Append Logs
    private func appendLogs(_ logs: [String]) {
        for log in logs {
            self.generationLogs += "\(log)\n"
        }
    }

    // Method to Save Image to Photo Library
    func saveImageToPhotos() {
        guard let image = generatedImage else {
            generationErrorMessage = "No image to save."
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        generationLogs += "Image saved to Photo Library.\n"
    }
}
