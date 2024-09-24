//
//  ImageGenView.swift
//  irl
//
//  Created by Elijah Arbee on 9/22/24.
// the response says the data couldnt be read beacue some is missing this is not specific enough

import SwiftUI

struct ImageGenView: View {
    // MARK: - State Objects for Services
    @StateObject private var fluxService = FluxImageGenerationService()
    @StateObject private var sdxlService = SDXLImageGenerationService() // Initialize without API key
    
    // MARK: - User Inputs
    @State private var selectedModel: String = "FLUX"  // Default selected model
    @State private var prompt: String = ""
    @State private var imageSize: String = "landscape_4_3"
    @State private var numImages: String = "1"
    @State private var outputFormat: String = "jpeg"
    @State private var guidanceScale: String = "3.5"
    @State private var numInferenceSteps: String = "28"
    @State private var enableSafetyChecker: Bool = true

    // MARK: - Available Models
    let availableModels = ["FLUX", "SDXL"] // Add more models here as needed

    // MARK: - Options
    let imageSizeOptions = ["square_hd", "square", "portrait_4_3", "portrait_16_9", "landscape_4_3", "landscape_16_9"]
    let outputFormatOptions = ["jpeg", "png"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Model Selection Picker
                    Text("Select Model:")
                        .font(.headline)
                    
                    Picker("Select Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Group {
                        // Image Description
                        Text("Enter Image Description:")
                            .font(.headline)
                        
                        TextEditor(text: $prompt)
                            .padding(4)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                        
                        // Image Size Picker
                        Text("Image Size:")
                            .font(.headline)
                        
                        Picker("Image Size", selection: $imageSize) {
                            ForEach(imageSizeOptions, id: \.self) { size in
                                Text(formatImageSize(size))
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Number of Images
                        Text("Number of Images:")
                            .font(.headline)
                        
                        TextField("Number of Images", text: $numImages)
                            .keyboardType(.numberPad)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        // Output Format Picker
                        Text("Output Format:")
                            .font(.headline)
                        
                        Picker("Output Format", selection: $outputFormat) {
                            ForEach(outputFormatOptions, id: \.self) { format in
                                Text(format.uppercased())
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Guidance Scale
                        Text("Guidance Scale:")
                            .font(.headline)
                        
                        TextField("Guidance Scale", text: $guidanceScale)
                            .keyboardType(.decimalPad)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        // Number of Inference Steps
                        Text("Number of Inference Steps:")
                            .font(.headline)
                        
                        TextField("Inference Steps", text: $numInferenceSteps)
                            .keyboardType(.numberPad)
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        // Enable Safety Checker Toggle
                        Toggle(isOn: $enableSafetyChecker) {
                            Text("Enable Safety Checker")
                                .font(.headline)
                        }
                    }
                    
                    // Generate Image Button
                    Button(action: generateImage) {
                        HStack {
                            if isGeneratingImage {
                                ProgressView()
                            }
                            Text("Generate Image")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isGeneratingImage ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isGeneratingImage || !isInputValid)
                    
                    // Logs Section
                    if let logs = currentLogs, !logs.isEmpty {
                        Text("Logs:")
                            .font(.headline)
                        
                        ScrollView {
                            Text(logs)
                                .font(.caption)
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .frame(height: 150)
                    }
                    
                    // Generated Image Display
                    if let urlString = currentGeneratedImageUrl, let url = URL(string: urlString) {
                        Text("Generated Image:")
                            .font(.headline)

                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(8)
                            case .failure:
                                Text("Failed to load image.")
                                    .foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .shadow(radius: 5)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("\(selectedModel) Image Generator")
            .alert(isPresented: Binding<Bool>(
                get: { currentErrorMessage != nil },
                set: { _ in
                    clearErrorMessage()
                }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(currentErrorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Computed Properties for Current Service States
    private var isGeneratingImage: Bool {
        switch selectedModel {
        case "SDXL":
            return sdxlService.isGeneratingImage
        default:
            return fluxService.isGeneratingImage
        }
    }
    
    private var currentLogs: String? {
        switch selectedModel {
        case "SDXL":
            return sdxlService.generationLogs
        default:
            return fluxService.generationLogs
        }
    }
    
    private var currentGeneratedImageUrl: String? {
        switch selectedModel {
        case "SDXL":
            return sdxlService.generatedImageUrl
        default:
            return fluxService.generatedImageUrl
        }
    }
    
    private var currentErrorMessage: String? {
        switch selectedModel {
        case "SDXL":
            return sdxlService.generationErrorMessage
        default:
            return fluxService.generationErrorMessage
        }
    }
    
    // MARK: - Input Validation
    private var isInputValid: Bool {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let numImagesInt = Int(numImages), numImagesInt > 0,
              let guidanceScaleDouble = Double(guidanceScale), guidanceScaleDouble > 0,
              let numInferenceStepsInt = Int(numInferenceSteps), numInferenceStepsInt > 0 else {
            return false
        }
        return true
    }
    
    // MARK: - Generate Image Action
    private func generateImage() {
        guard isInputValid else {
            currentErrorMessageHandler("Please ensure all inputs are valid.")
            return
        }
        
        switch selectedModel {
        case "SDXL":
            sdxlService.generateImage(
                fromPrompt: prompt,
                imageSize: imageSize,
                numImages: Int(numImages) ?? 1,
                outputFormat: outputFormat,
                guidanceScale: Double(guidanceScale) ?? 3.5,
                numInferenceSteps: Int(numInferenceSteps) ?? 28,
                enableSafetyChecker: enableSafetyChecker
            )
        default:
            fluxService.generateImage(
                fromPrompt: prompt,
                imageSize: imageSize,
                numImages: Int(numImages) ?? 1,
                outputFormat: outputFormat,
                guidanceScale: Double(guidanceScale) ?? 3.5,
                numInferenceSteps: Int(numInferenceSteps) ?? 28,
                enableSafetyChecker: enableSafetyChecker
            )
        }
    }
    
    // MARK: - Handle Error Messages
    private func currentErrorMessageHandler(_ message: String) {
        switch selectedModel {
        case "SDXL":
            sdxlService.generationErrorMessage = message
        default:
            fluxService.generationErrorMessage = message
        }
    }
    
    private func clearErrorMessage() {
        switch selectedModel {
        case "SDXL":
            sdxlService.generationErrorMessage = nil
        default:
            fluxService.generationErrorMessage = nil
        }
    }
    
    // MARK: - Helper Function to Format Image Size Display
    private func formatImageSize(_ size: String) -> String {
        switch size {
        case "square_hd":
            return "Square HD"
        case "square":
            return "Square"
        case "portrait_4_3":
            return "Portrait 4:3"
        case "portrait_16_9":
            return "Portrait 16:9"
        case "landscape_4_3":
            return "Landscape 4:3"
        case "landscape_16_9":
            return "Landscape 16:9"
        default:
            return size.capitalized
        }
    }
}

struct ImageGenView_Previews: PreviewProvider {
    static var previews: some View {
        ImageGenView()
    }
}
