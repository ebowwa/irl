//
//  EmotionUtilities.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI

func emotionColor(for emotion: String) -> Color {
    let hash = emotion.lowercased().hashValue
    let hue = Double(abs(hash) % 360) / 360.0
    return Color(hue: hue, saturation: 0.7, brightness: 0.9)
}
