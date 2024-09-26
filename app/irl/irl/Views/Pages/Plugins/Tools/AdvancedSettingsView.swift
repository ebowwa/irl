//
//  AdvancedSettingsView.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
import SwiftUI

struct AdvancedSettingsView: View {
    @ObservedObject var viewModel: ChatParametersViewModel
    
    var body: some View {
        Form {
            Section(header: Text("Model")) {
                Picker("Model", selection: $viewModel.model) {
                    // Use available models from Constants.AI_MODELS
                    // really should be consistent with the model api state
                    // maybe the @Published property
                    ForEach(Array(Constants.AI_MODELS.models.keys), id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                // Set the default selection to hauki-3 in the UI if no model is selected
                .onAppear {
                    if viewModel.model.isEmpty {
                        viewModel.model = Constants.AI_MODELS.haiku
                    }
                }
            }
            
            Section(header: Text("Parameters")) {
                Stepper("Max Tokens: \(viewModel.maxTokens)", value: $viewModel.maxTokens, in: 1...2000)
                
                VStack(alignment: .leading) {
                    Text("Temperature: \(viewModel.temperature, specifier: "%.1f")")
                    Slider(value: $viewModel.temperature, in: 0...1, step: 0.1)
                }
            }
            
            Section(header: Text("System Prompt")) {
                TextEditor(text: $viewModel.systemPrompt)
                    .frame(height: 100)
            }
        }
    }
}
