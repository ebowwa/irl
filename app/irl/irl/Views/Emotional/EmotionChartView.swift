//
//  EmotionChartView.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI

// MARK: - EmotionChartView

struct EmotionChartView: View {
    let emotions: [Emotion]
    @State private var phase: CGFloat = 0
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack {
                    ForEach(filteredEmotions.indices, id: \.self) { index in
                        let emotion = filteredEmotions[index]
                        WaveShape(
                            amplitude: CGFloat(emotion.score) * (geometry.size.height / 4),
                            frequency: CGFloat(2 + index),
                            phase: phase + CGFloat(index)
                        )
                        .stroke(emotionColor(for: emotion.name).opacity(0.7), lineWidth: 2)
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
                            Text(emotion.name)
                                .font(.caption)
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .padding(.top, 10)
            }
        }
    }
    
    private var filteredEmotions: [Emotion] {
        emotions.filter { $0.score > 0.1 }
    }
}
