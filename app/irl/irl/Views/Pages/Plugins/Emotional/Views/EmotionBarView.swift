//
//  EmotionBarView.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI

struct EmotionBarView: View {
    let emotion: Emotion
    var compact: Bool = false
    
    var body: some View {
        HStack {
            Text(emotion.name)
                .frame(width: compact ? 100 : 150, alignment: .leading)
                .font(compact ? .caption : .body)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    Rectangle()
                        .fill(emotionColor(for: emotion.name))
                        .frame(width: CGFloat(emotion.score) * geometry.size.width)
                }
            }
            .frame(height: compact ? 15 : 20)
            Text(String(format: "%.2f", emotion.score))
                .font(compact ? .caption : .body)
        }
    }
}
