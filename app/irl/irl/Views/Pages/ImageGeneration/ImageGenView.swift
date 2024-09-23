//
//  ImageGenView.swift
//  irl
//
//  Created by Elijah Arbee on 9/22/24.
//
//  rethink the selector for the models,  i do not want the toggle as i will likely add further models as well 
import SwiftUI

struct ImageGenView: View {
    // MARK: - State Objects for Services
    @StateObject private var fluxService = FluxImageGenerationService()
    // StateObject to handle FLUX image generation service, this object manages the state of the service
    @StateObject private var sdxlService = SDXLImageGenerationService()
    // StateObject for SDXL image generation service, handles the state of this alternative service
    
    // MARK: - User Inputs
    @State private var useSDXL = false  // Toggle between FLUX and SDXL models, the state will persist until the view is destroyed
    @State private var prompt: String = ""  // Holds the user prompt for image generation, state persists within the view
    @State private var imageSize: String = "landscape_4_3" // State for the selected image size
    @State private var numImages: String = "1" // Holds the number of images user wants to generate
    @State private var outputFormat: String = "jpeg" // State for output image format (e.g., jpeg, png)
    @State private var guidanceScale: String = "3.5" // Adjusts the guidance scale, stored in local state
    @State private var numInferenceSteps: String = "28" // Holds the number of inference steps for the image generation
    @State private var enableSafetyChecker: Bool = true // Safety checker state, helps prevent inappropriate content generation
    
    // MARK: - Options
    let imageSizeOptions = ["square_hd", "square", "portrait_4_3", "portrait_16_9", "landscape_4_3", "landscape_16_9"]
    let outputFormatOptions = ["jpeg", "png"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Toggle between FLUX and SDXL models
                    Toggle("Use SDXL Model", isOn: $useSDXL)
                        .font(.headline)
                        .padding(.top)
                    
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
            .navigationTitle(useSDXL ? "SDXL Image Generator" : "FLUX.1 Image Generator")
            .alert(isPresented: Binding<Bool>(
                get: { currentErrorMessage != nil },
                set: { _ in
                    if useSDXL {
                        sdxlService.generationErrorMessage = nil
                    } else {
                        fluxService.generationErrorMessage = nil
                    }
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
        return useSDXL ? sdxlService.isGeneratingImage : fluxService.isGeneratingImage
    }
    
    private var currentLogs: String? {
        return useSDXL ? sdxlService.generationLogs : fluxService.generationLogs
    }
    
    private var currentGeneratedImageUrl: String? {
        return useSDXL ? sdxlService.generatedImageUrl : fluxService.generatedImageUrl
    }
    
    private var currentErrorMessage: String? {
        return useSDXL ? sdxlService.generationErrorMessage : fluxService.generationErrorMessage
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
        
        if useSDXL {
            sdxlService.generateImage(
                fromPrompt: prompt,
                imageSize: imageSize,
                numImages: Int(numImages) ?? 1,
                outputFormat: outputFormat,
                guidanceScale: Double(guidanceScale) ?? 3.5,
                numInferenceSteps: Int(numInferenceSteps) ?? 28,
                enableSafetyChecker: enableSafetyChecker
            )
        } else {
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
        if useSDXL {
            sdxlService.generationErrorMessage = message
        } else {
            fluxService.generationErrorMessage = message
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
