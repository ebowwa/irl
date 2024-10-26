//
//  GradientPulsatingButton.swift
//  irl
//
//  Created by Elijah Arbee on 10/2/24.
//
import SwiftUI

struct GradientPulsatingButton: View {
    var imageName: String
    var gradientColors: [Color]
    var buttonSize: CGFloat
    var shadowColor: Color
    var shadowRadius: CGFloat
    var shadowOffsetX: CGFloat
    var shadowOffsetY: CGFloat
    
    @State private var pulsate = false
    
    var body: some View {
        Image(systemName: imageName)
            .font(.system(size: buttonSize))
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(gradient: Gradient(colors: gradientColors),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .cornerRadius(buttonSize / 2)
                    .shadow(color: shadowColor.opacity(0.6), radius: shadowRadius, x: shadowOffsetX, y: shadowOffsetY)
            )
            .scaleEffect(pulsate ? 1.1 : 1.0)
            .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulsate)
            .onAppear {
                pulsate = true
            }
    }
}

