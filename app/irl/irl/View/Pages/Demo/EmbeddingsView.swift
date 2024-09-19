//
//  EmbeddingsView.swift
//  irl
//
//  Created by Elijah Arbee on 9/18/24.
//
// TODO: MODULARIZE this script so that the embeddings post & response are handled in an imported script that can be used easily in existing ui
//
//  EmbeddingsView.swift
//  irl
//
//  Created by Elijah Arbee on 9/18/24.
//
import SwiftUI

class EmbeddingsViewModel: ObservableObject {
    @Published var result: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func getEmbedding(for text: String) {
        isLoading = true
        errorMessage = nil
        result = ""
        
        Task {
            do {
                let response = try await EmbeddingService.shared.getEmbedding(for: text)
                DispatchQueue.main.async {
                    self.result = """
                        Embedding received:
                        Model: \(response.metadata.model)
                        Dimensions: \(response.metadata.dimensions)
                        Token count: \(response.metadata.token_count)
                        Input character count: \(response.metadata.input_char_count)
                        Normalized: \(response.metadata.normalized)
                        First 5 values: \(response.embedding.prefix(5))
                        """
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

struct BasicEmbeddingsView: View {
    @StateObject private var viewModel = EmbeddingsViewModel()
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            TextField("Enter text", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Get Embedding") {
                viewModel.getEmbedding(for: inputText)
            }
            .disabled(inputText.isEmpty || viewModel.isLoading)
            .padding()
            
            if viewModel.isLoading {
                ProgressView()
            } else if !viewModel.result.isEmpty {
                Text(viewModel.result)
                    .padding()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}
