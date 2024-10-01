//
//  ImageGenHelper.swift
//  irl
//
//  Created by Elijah Arbee on 9/25/24.
//
import Foundation

// Helper to format image size based on the key
func formatImageSize(key: String) -> String {
    imageSizeOptions[key] ?? key.capitalized
}

// Helper to validate input fields
func isValidInput(prompt: String, numImages: String, guidance: String, steps: String) -> Bool {
    guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
          let numImagesInt = Int(numImages), numImagesInt > 0,
          let guidanceScaleDouble = Double(guidance), guidanceScaleDouble > 0,
          let numInferenceStepsInt = Int(steps), numInferenceStepsInt > 0 else {
        return false
    }
    return true
}
