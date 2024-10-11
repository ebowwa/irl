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
                    // Use available models from ConstantAIModels
                    ForEach(Array(ConstantAIModels.models.keys), id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                // Set the default selection to haiku in the UI if no model is selected
                .onAppear {
                    if viewModel.model.isEmpty {
                        viewModel.model = ConstantAIModels.haiku
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
