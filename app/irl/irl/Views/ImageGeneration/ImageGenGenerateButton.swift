//
//  ImageGenGenerateButton.swift
//  irl
//
//  Created by Elijah Arbee on 9/25/24.
//
import SwiftUI

struct ImageGenGenerateButton: View {
    let isGenerating: Bool
    let isInputValid: Bool
    let onGenerate: () -> Void

    var body: some View {
        Button(action: onGenerate) {
            HStack {
                if isGenerating {
                    ProgressView()
                }
                Text("Generate Image")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .background(isGenerating ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(isGenerating || !isInputValid)
    }
}
