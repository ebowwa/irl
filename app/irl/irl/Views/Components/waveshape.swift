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
    var amplitude: Double
    var frequency: Double
    var phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at the left-middle
        path.move(to: CGPoint(x: 0, y: rect.midY))
        
        // Draw the sine wave using Double for higher precision
        for x in stride(from: 0.0, through: Double(rect.width), by: 1.0) {
            let relativeX = x / Double(rect.width)
            let angle = relativeX * frequency * 2 * Double.pi + phase
            let y = Double(rect.midY) + amplitude * sin(angle)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}
