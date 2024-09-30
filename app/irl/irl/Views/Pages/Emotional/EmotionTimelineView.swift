//
//  EmotionTimelineView.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI
import Charts

struct EmotionTimelineView: View {
    let timeline: [(Int, [Emotion])]
    
    var body: some View {
        Chart {
            ForEach(timeline, id: \.0) { index, emotions in
                ForEach(emotions.filter { $0.score > 0.3 }) { emotion in
                    LineMark(
                        x: .value("Sentence", index),
                        y: .value("Score", emotion.score)
                    )
                    .foregroundStyle(emotionColor(for: emotion.name))
                }
            }
        }
    }
}
