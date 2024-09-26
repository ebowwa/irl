//
//  EmotionChartView.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI
import Charts

struct EmotionChartView: View {
    let emotions: [Emotion]
    
    var body: some View {
        Chart {
            ForEach(emotions.filter { $0.score > 0.1 }) { emotion in
                BarMark(
                    x: .value("Emotion", emotion.name),
                    y: .value("Score", emotion.score)
                )
                .foregroundStyle(emotionColor(for: emotion.name))
            }
        }
    }
}
