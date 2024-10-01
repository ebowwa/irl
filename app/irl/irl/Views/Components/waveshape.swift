//
//  waveshape.swift
//  irl
//
//  Created by Elijah Arbee on 10/1/24.
//
import SwiftUI
import Numerics

// MARK: - WaveShape

struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at the left-middle
        path.move(to: CGPoint(x: 0, y: rect.midY))
        
        // Draw the sine wave
        for x in stride(from: 0, through: rect.width, by: 1) {
            let relativeX = x / rect.width
            let angle = relativeX * frequency * 2 * RealType.pi + phase
            let y = rect.midY + amplitude * RealType.sin(angle)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}
