import Foundation
import SwiftUI

enum ImageSize: String, CaseIterable {
    case square_hd = "square_hd"
    case square = "square"
    case portrait_4_3 = "portrait_4_3"
    case portrait_16_9 = "portrait_16_9"
    case landscape_4_3 = "landscape_4_3"
    case landscape_16_9 = "landscape_16_9"
}

enum OutputFormat: String, CaseIterable {
    case jpeg = "jpeg"
    case png = "png"
}

struct LoraConfig: Codable {
    let url: String
    let fileName: String
    let fileSize: Int
    let contentType: String
    
    enum CodingKeys: String, CodingKey {
        case url
        case fileName = "file_name"
        case fileSize = "file_size"
        case contentType = "content_type"
    }
}

struct LoraFiles: Codable, Identifiable {
    let id = UUID()
    let configFile: LoraConfig
    let diffusersLoraFile: LoraConfig
    var scale: Double
    
    enum CodingKeys: String, CodingKey {
        case configFile = "config_file"
        case diffusersLoraFile = "diffusers_lora_file"
        case scale
    }
}

struct LoraWeight: Codable {
    let path: String
    let scale: Double
}

struct ImageGenerationRequest: Codable {
    let prompt: String
    let imageSize: String
    let numInferenceSteps: Int
    let seed: Int?
    let loras: [LoraWeight]
    let guidanceScale: Double
    let syncMode: Bool
    let numImages: Int
    let enableSafetyChecker: Bool
    let outputFormat: String
    
    enum CodingKeys: String, CodingKey {
        case prompt
        case imageSize = "image_size"
        case numInferenceSteps = "num_inference_steps"
        case seed
        case loras
        case guidanceScale = "guidance_scale"
        case syncMode = "sync_mode"
        case numImages = "num_images"
        case enableSafetyChecker = "enable_safety_checker"
        case outputFormat = "output_format"
    }
}

@MainActor
class ImageGenerationViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var selectedSize: ImageSize = .landscape_4_3
    @Published var numInferenceSteps: Double = 28
    @Published var seed: String = ""
    @Published var loraFiles: [LoraFiles] = []
    @Published var guidanceScale: Double = 3.5
    @Published var syncMode: Bool = false
    @Published var numImages: Double = 1
    @Published var enableSafetyChecker: Bool = true
    @Published var selectedFormat: OutputFormat = .jpeg
    
    // For LoRA JSON input
    @Published var loraJsonInput: String = ""
    @Published var newLoraScale: Double = 1.0
    
    @Published var generatedImages: [UIImage] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var requestId: String?
    @Published var progress: Int = 0
    @Published var inferenceTime: Double?
    @Published var hasNSFWContent: Bool = false
    
    private let baseURL = "http://localhost:8000"
    
    // Response models
    struct GeneratedImage: Codable {
        let url: String
        let width: Int
        let height: Int
        let contentType: String
        
        enum CodingKeys: String, CodingKey {
            case url
            case width
            case height
            case contentType = "content_type"
        }
    }
    
    struct TimingInfo: Codable {
        let inference: Double
    }
    
    struct FluxResponse: Codable {
        let seed: Int
        let images: [GeneratedImage]
        let prompt: String
        let timings: TimingInfo
        let hasNSFWConcepts: [Bool]
        
        enum CodingKeys: String, CodingKey {
            case seed
            case images
            case prompt
            case timings
            case hasNSFWConcepts = "has_nsfw_concepts"
        }
    }
    
    struct StatusResponse: Codable {
        let status: String
        let progress: Int?
        let result: FluxResponse?
        let error: String?
    }
    
    func addLoraFromJson() {
        guard !loraJsonInput.isEmpty else { return }
        
        do {
            let decoder = JSONDecoder()
            var jsonData = loraJsonInput.data(using: .utf8)!
            
            // Parse the JSON input
            let loraConfig = try decoder.decode([String: LoraConfig].self, from: jsonData)
            
            guard let configFile = loraConfig["config_file"],
                  let diffusersLoraFile = loraConfig["diffusers_lora_file"] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid LoRA configuration"])
            }
            
            let loraFiles = LoraFiles(
                configFile: configFile,
                diffusersLoraFile: diffusersLoraFile,
                scale: newLoraScale
            )
            
            self.loraFiles.append(loraFiles)
            loraJsonInput = ""
            newLoraScale = 1.0
            
        } catch {
            errorMessage = "Error parsing LoRA JSON: \(error.localizedDescription)"
        }
    }
    
    func removeLoraFiles(at offsets: IndexSet) {
        loraFiles.remove(atOffsets: offsets)
    }
    
    func generateImage() async {
        isLoading = true
        errorMessage = nil
        
        // Convert LoraFiles to LoraWeight array
        let loraWeights = loraFiles.map { loraFile in
            LoraWeight(
                path: loraFile.diffusersLoraFile.url,
                scale: loraFile.scale
            )
        }
        
        let request = ImageGenerationRequest(
            prompt: prompt,
            imageSize: selectedSize.rawValue,
            numInferenceSteps: Int(numInferenceSteps),
            seed: Int(seed),
            loras: loraWeights,
            guidanceScale: guidanceScale,
            syncMode: syncMode,
            numImages: Int(numImages),
            enableSafetyChecker: enableSafetyChecker,
            outputFormat: selectedFormat.rawValue
        )
        
        do {
            let url = URL(string: "\(baseURL)/generate_image")!
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Decode the response
            let decoder = JSONDecoder()
            if syncMode {
                // In sync mode, we expect the complete response
                let fluxResponse = try decoder.decode(FluxResponse.self, from: data)
                await processFluxResponse(fluxResponse)
            } else {
                // In async mode, we get a request ID
                struct RequestResponse: Codable {
                    let request_id: String
                }
                let requestResponse = try decoder.decode(RequestResponse.self, from: data)
                requestId = requestResponse.request_id
                // Start polling for the result
                await pollForResult(requestId: requestResponse.request_id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func pollForResult(requestId: String) async {
        let pollURL = URL(string: "\(baseURL)/status/\(requestId)")!
        
        // Poll every 2 seconds for up to 60 seconds
        for _ in 0..<30 {
            do {
                let (data, response) = try await URLSession.shared.data(from: pollURL)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    continue
                }
                
                if httpResponse.statusCode == 404 {
                    await MainActor.run {
                        errorMessage = "Request not found"
                        self.requestId = nil
                    }
                    return
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    continue
                }
                
                let decoder = JSONDecoder()
                let statusResponse = try decoder.decode(StatusResponse.self, from: data)
                
                // Update progress
                if let currentProgress = statusResponse.progress {
                    await MainActor.run {
                        self.progress = currentProgress
                    }
                }
                
                switch statusResponse.status {
                case "completed":
                    if let result = statusResponse.result {
                        await processFluxResponse(result)
                        return
                    }
                case "failed":
                    await MainActor.run {
                        errorMessage = statusResponse.error ?? "Image generation failed"
                        self.requestId = nil
                    }
                    return
                case "processing", "queued":
                    break
                default:
                    await MainActor.run {
                        errorMessage = "Unknown status: \(statusResponse.status)"
                        self.requestId = nil
                    }
                    return
                }
                
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                await MainActor.run {
                    errorMessage = "Error checking status: \(error.localizedDescription)"
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        
        await MainActor.run {
            errorMessage = "Request timed out after 60 seconds"
            self.requestId = nil
        }
    }
    
    private func processFluxResponse(_ response: FluxResponse) async {
        await MainActor.run {
            print("Processing Flux response with \(response.images.count) images")
            // Clear any previous images and error messages
            generatedImages.removeAll()
            errorMessage = nil
            progress = 100
        }
        
        let urlSession = URLSession(configuration: .ephemeral)
        
        for imageInfo in response.images {
            do {
                print("Attempting to load image from URL: \(imageInfo.url)")
                let url = URL(string: imageInfo.url)!
                var request = URLRequest(url: url)
                request.cachePolicy = .reloadIgnoringLocalCacheData
                
                let (data, urlResponse) = try await urlSession.data(for: request)
                print("Received response: \(urlResponse)")
                
                if let httpResponse = urlResponse as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    print("Content-Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "none")")
                    print("Content Length: \(data.count) bytes")
                }
                
                if let image = UIImage(data: data) {
                    print("Successfully created UIImage from data")
                    await MainActor.run {
                        generatedImages.append(image)
                        inferenceTime = response.timings.inference
                        hasNSFWContent = response.hasNSFWConcepts.contains(true)
                        self.requestId = nil
                        isLoading = false
                    }
                } else {
                    print("Failed to create UIImage from data of size: \(data.count)")
                    throw NSError(domain: "ImageLoading", code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data (size: \(data.count) bytes)"])
                }
            } catch {
                print("Error loading image: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Error loading image: \(error.localizedDescription)"
                    isLoading = false
                    self.requestId = nil
                }
            }
        }
        
        if await MainActor.run(body: { generatedImages.isEmpty }) {
            print("No images were loaded successfully")
            await MainActor.run {
                errorMessage = "No images were generated successfully"
                isLoading = false
                self.requestId = nil
            }
        }
    }
}
