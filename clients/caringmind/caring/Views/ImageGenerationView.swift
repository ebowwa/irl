// this was for experiementing but will not replace explore as explore will be fun day/weeks in the life of {user}
// works with bugs and server isnt integrated into production
import SwiftUI

struct ImageGenerationView: View {
    @StateObject private var viewModel = ImageGenerationViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prompt")) {
                    TextField("Enter your prompt", text: $viewModel.prompt)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("LoRA Settings")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Paste LoRA JSON Configuration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $viewModel.loraJsonInput)
                            .frame(height: 100)
                            .font(.system(.body, design: .monospaced))
                        
                        HStack {
                            Text("Scale: \(viewModel.newLoraScale, specifier: "%.2f")")
                            Slider(value: $viewModel.newLoraScale, in: 0...2, step: 0.1)
                        }
                        
                        Button(action: viewModel.addLoraFromJson) {
                            Text("Add LoRA")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(viewModel.loraJsonInput.isEmpty)
                        .buttonStyle(.bordered)
                    }
                    
                    if !viewModel.loraFiles.isEmpty {
                        ForEach(viewModel.loraFiles) { lora in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Config: \(lora.configFile.fileName)")
                                    .font(.caption)
                                Text("Weights: \(lora.diffusersLoraFile.fileName)")
                                    .font(.caption)
                                Text("Scale: \(lora.scale, specifier: "%.2f")")
                                    .font(.caption)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: viewModel.removeLoraFiles)
                    }
                }
                
                Section(header: Text("Image Settings")) {
                    Picker("Size", selection: $viewModel.selectedSize) {
                        ForEach(ImageSize.allCases, id: \.self) { size in
                            Text(size.rawValue).tag(size)
                        }
                    }
                    
                    HStack {
                        Text("Steps: \(Int(viewModel.numInferenceSteps))")
                        Slider(value: $viewModel.numInferenceSteps, in: 1...50, step: 1)
                    }
                    
                    TextField("Seed (optional)", text: $viewModel.seed)
                        .keyboardType(.numberPad)
                    
                    HStack {
                        Text("Guidance: \(viewModel.guidanceScale, specifier: "%.1f")")
                        Slider(value: $viewModel.guidanceScale, in: 1...20)
                    }
                    
                    Toggle("Sync Mode", isOn: $viewModel.syncMode)
                    
                    HStack {
                        Text("Number of Images: \(Int(viewModel.numImages))")
                        Slider(value: $viewModel.numImages, in: 1...4, step: 1)
                    }
                    
                    Toggle("Safety Checker", isOn: $viewModel.enableSafetyChecker)
                    
                    Picker("Format", selection: $viewModel.selectedFormat) {
                        ForEach(OutputFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await viewModel.generateImage()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text(viewModel.isLoading ? "Generating... \(viewModel.progress)%" : "Generate Image")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.prompt.isEmpty || viewModel.isLoading)
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                if !viewModel.generatedImages.isEmpty {
                    Section(header: Text("Generated Images")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.generatedImages, id: \.self) { image in
                                    VStack {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 200)
                                            .cornerRadius(8)
                                        
                                        if let inferenceTime = viewModel.inferenceTime {
                                            Text("Generated in \(String(format: "%.2f", inferenceTime))s")
                                                .font(.caption)
                                        }
                                        
                                        if viewModel.hasNSFWContent {
                                            Text("⚠️ NSFW Content Detected")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Image Generation")
        }
    }
}

#Preview {
    ImageGenerationView()
}
