//
//  SDXLService.swift
//  irl
//
//  Created by Elijah Arbee on 9/23/24.
//
import Combine
import Foundation

class SDXLImageGenerationService: ObservableObject {
    @Published var isGeneratingImage = false
    @Published var generatedImageUrl: String?
    @Published var generationErrorMessage: String?
    @Published var generationLogs: String = ""

    private var cancellables = Set<AnyCancellable>()

    func generateImage(
        fromPrompt prompt: String,
        imageSize: String,
        numImages: Int,
        outputFormat: String,
        guidanceScale: Double,
        numInferenceSteps: Int,
        enableSafetyChecker: Bool
    ) {
        isGeneratingImage = true
        generationLogs = "Generating SDXL image..."

        // Construct the API URL using Constants
        guard let requestURL = URL(string: Constants.API.baseURL + Constants.API.Paths.sdxlGenerate) else {
            generationErrorMessage = "Invalid API URL"
            isGeneratingImage = false
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "prompt": prompt,
            "image_size": imageSize,
            "num_images": numImages,
            "format": outputFormat,
            "guidance_scale": guidanceScale,
            "num_inference_steps": numInferenceSteps,
            "enable_safety_checker": enableSafetyChecker
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            generationErrorMessage = "Failed to serialize the request body"
            isGeneratingImage = false
            return
        }

        // Make the API call
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SDXLImageGenerationResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    self.generationErrorMessage = "Failed to generate image: \(error.localizedDescription)"
                case .finished:
                    break
                }
                self.isGeneratingImage = false
            } receiveValue: { [weak self] response in
                self?.generatedImageUrl = response.images.first?.url
                self?.generationLogs = "Image generated with seed: \(response.seed)"
            }
            .store(in: &cancellables)
    }
}

// Response Model for SDXL Image Generation
struct SDXLImageGenerationResponse: Decodable {
    let seed: UInt64
    let images: [GeneratedSDXLImage]
    let prompt: String
    let timings: SDXLTimings
    let has_nsfw_concepts: [Bool]
}

// Generated Image Data
struct GeneratedSDXLImage: Decodable {
    let url: String
    let width: Int
    let height: Int
    let content_type: String
}

// Timing Information
struct SDXLTimings: Decodable {
    let inference: Double
}
