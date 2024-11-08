//
//  EmotionChartView.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI

// MARK: - EmotionChartView

struct EmotionChartView: View {
    let emotions: [MainEmotion]
    @State private var phase: CGFloat = 0
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack {
                    ForEach(filteredEmotions.indices, id: \.self) { index in
                        let emotion = filteredEmotions[index]
                        let amplitude = CGFloat(emotion.score) * (geometry.size.height / 4)
                        let frequency = CGFloat(2 + index)
                        let adjustedPhase = phase + CGFloat(index)
                        
                        WaveShape(
                            amplitude: amplitude,
                            frequency: frequency,
                            phase: adjustedPhase
                        )
                        .stroke(emotionColor(for: emotion.name).opacity(0.7), lineWidth: 2)
                        
                        // Calculate the peak position for the label
                        let peakX = geometry.size.width / 2
                        let peakY = geometry.size.height / 2 - amplitude
                        
                        // Add numerical label at the peak of each wave
                        Text(String(format: "%.2f", emotion.score))
                            .font(.caption)
                            .foregroundColor(emotionColor(for: emotion.name))
                            .position(x: peakX, y: peakY)
                    }
                }
                .padding()
                .onAppear {
                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                        phase += 2 * .pi
                    }
                }
            }
            .frame(height: 200)
            
            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(filteredEmotions) { emotion in
                        HStack {
                            Circle()
                                .fill(emotionColor(for: emotion.name))
                                .frame(width: 10, height: 10)
                            Text("\(emotion.name) (\(String(format: "%.2f", emotion.score)))")
                                .font(.caption)
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .padding(.top, 10)
            }
        }
    }
    
    private var filteredEmotions: [MainEmotion] {
        emotions.filter { $0.score > 0.1 }
    }
}
