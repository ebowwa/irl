//
//  ImageGenView.swift
//  irl
//
//  Created by Elijah Arbee on 9/22/24.
//
import SwiftUI

struct ImageGenView: View {
    @StateObject private var fluxImageService = FluxImageGenerationService()
    @StateObject private var sdxlImageService = SDXLImageGenerationService()

    @State private var selectedModel: String = "SDXL"
    @State private var promptText: String = ""
    @State private var imageSize: String = "landscape_4_3"
    @State private var numOfImages: String = "1"
    @State private var outputFormat: String = "jpeg"
    @State private var guidanceScale: String = "3.5"
    @State private var inferenceSteps: String = "28"
    @State private var safetyCheckerEnabled: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Generation Input Fields
                    ImageGenInputFields(
                        selectedModel: $selectedModel,
                        promptText: $promptText,
                        imageSize: $imageSize,
                        numOfImages: $numOfImages,
                        outputFormat: $outputFormat,
                        guidanceScale: $guidanceScale,
                        inferenceSteps: $inferenceSteps,
                        safetyCheckerEnabled: $safetyCheckerEnabled
                    )

                    // Generate Button
                    ImageGenGenerateButton(
                        isGenerating: isGeneratingImage,
                        isInputValid: isValidInput(
                            prompt: promptText,
                            numImages: numOfImages,
                            guidance: guidanceScale,
                            steps: inferenceSteps
                        ),
                        onGenerate: generateImage
                    )

                    // Logs Display
                    ImageGenLogsDisplay(generationLogs: currentGenerationLogs)

                    // Display Generated Image
                    ImageGenOutputView(imageUrlString: currentGeneratedImageUrl)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("\(selectedModel) Image Generator")
            .alert(isPresented: Binding<Bool>(
                get: { currentErrorMessage != nil },
                set: { _ in clearErrorMessage() }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(currentErrorMessage ?? "An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Computed Properties

    private var isGeneratingImage: Bool {
        switch selectedModel {
        case "SDXL":
            return sdxlImageService.isGeneratingImage
        default:
            return fluxImageService.isGeneratingImage
        }
    }

    private var currentGenerationLogs: String? {
        switch selectedModel {
        case "SDXL":
            return sdxlImageService.generationLogs
        default:
            return fluxImageService.generationLogs
        }
    }

    private var currentGeneratedImageUrl: String? {
        switch selectedModel {
        case "SDXL":
            return sdxlImageService.generatedImageUrl
        default:
            return fluxImageService.generatedImageUrl
        }
    }

    private var currentErrorMessage: String? {
        switch selectedModel {
        case "SDXL":
            return sdxlImageService.generationErrorMessage
        default:
            return fluxImageService.generationErrorMessage
        }
    }

    // MARK: - Validation for Inputs

    private func isValidInput(prompt: String, numImages: String, guidance: String, steps: String) -> Bool {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let numImagesInt = Int(numImages), numImagesInt > 0,
              let guidanceScaleDouble = Double(guidance), guidanceScaleDouble > 0,
              let numInferenceStepsInt = Int(steps), numInferenceStepsInt > 0 else {
            return false
        }
        return true
    }

    // MARK: - Generate Image Action

    private func generateImage() {
        guard isValidInput(
            prompt: promptText,
            numImages: numOfImages,
            guidance: guidanceScale,
            steps: inferenceSteps
        ) else {
            currentErrorMessageHandler("Please ensure all inputs are valid.")
            return
        }

        switch selectedModel {
        case "SDXL":
            sdxlImageService.generateImage(
                fromPrompt: promptText,
                imageSize: imageSize,
                numImages: Int(numOfImages) ?? 1,
                outputFormat: outputFormat,
                guidanceScale: Double(guidanceScale) ?? 3.5,
                numInferenceSteps: Int(inferenceSteps) ?? 28,
                enableSafetyChecker: safetyCheckerEnabled
            )
        default:
            fluxImageService.generateImage(
                fromPrompt: promptText,
                imageSize: imageSize,
                numImages: Int(numOfImages) ?? 1,
                outputFormat: outputFormat,
                guidanceScale: Double(guidanceScale) ?? 3.5,
                numInferenceSteps: Int(inferenceSteps) ?? 28,
                enableSafetyChecker: safetyCheckerEnabled
            )
        }
    }

    // MARK: - Handle Error Messages

    private func currentErrorMessageHandler(_ message: String) {
        switch selectedModel {
        case "SDXL":
            sdxlImageService.generationErrorMessage = message
        default:
            fluxImageService.generationErrorMessage = message
        }
    }

    private func clearErrorMessage() {
        switch selectedModel {
        case "SDXL":
            sdxlImageService.generationErrorMessage = nil
        default:
            fluxImageService.generationErrorMessage = nil
        }
    }
}

struct ImageGenView_Previews: PreviewProvider {
    static var previews: some View {
        ImageGenView()
    }
}
