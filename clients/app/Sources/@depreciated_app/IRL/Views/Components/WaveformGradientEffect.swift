//
//  WaveformGradientEffect.swift
//  irl
//
//  Created by Elijah Arbee on 10/8/24.
//

import Foundation
import SwiftUI

// Reusable gradient effect for waveform
struct WaveformGradientEffect: View {
    @Binding var gradientShift: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple, Color.blue]),
                               startPoint: gradientShift ? .leading : .trailing,
                               endPoint: gradientShift ? .trailing : .leading)
            )
            .frame(width: 150, height: 40)
            .animation(Animation.linear(duration: 2), value: gradientShift)
            .onAppear {
                self.gradientShift = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.gradientShift = false
                }
            }
    }
}
