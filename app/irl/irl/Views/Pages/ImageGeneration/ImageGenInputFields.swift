//
//  ImageGenInputFields.swift
//  irl
//
//  Created by Elijah Arbee on 9/25/24.
//
import SwiftUI

struct InputPicker: View {
    let label: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.headline)
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.capitalized).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

struct InputTextEditor: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.headline)
            TextEditor(text: $text)
                .padding(4)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .autocapitalization(.none)
        }
    }
}

struct InputTextField: View {
    let label: String
    @Binding var value: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.headline)
            TextField(label, text: $value)
                .keyboardType(keyboardType)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

struct ImageGenInputFields: View {
    @Binding var selectedModel: String
    @Binding var promptText: String
    @Binding var imageSize: String
    @Binding var numOfImages: String
    @Binding var outputFormat: String
    @Binding var guidanceScale: String
    @Binding var inferenceSteps: String
    @Binding var safetyCheckerEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Model Picker
            InputPicker(label: "Select Model", selection: $selectedModel, options: imageGenerationModels)

            // Image Prompt Editor
            InputTextEditor(label: "Enter Image Prompt", text: $promptText)

            // Image Size Picker
            InputPicker(label: "Image Size", selection: $imageSize, options: Array(imageSizeOptions.keys))

            // Number of Images TextField
            InputTextField(label: "Number of Images", value: $numOfImages, keyboardType: .numberPad)

            // Guidance Scale TextField
            InputTextField(label: "Guidance Scale", value: $guidanceScale, keyboardType: .decimalPad)

            // Inference Steps TextField
            InputTextField(label: "Inference Steps", value: $inferenceSteps, keyboardType: .numberPad)

            // Output Format Picker
            InputPicker(label: "Output Format", selection: $outputFormat, options: outputFormatOptions)

            // Safety Checker Toggle
            Toggle(isOn: $safetyCheckerEnabled) {
                Text("Enable Safety Checker").font(.headline)
            }
        }
    }
}
