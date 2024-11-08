//
//  EmotionalTranscriptView.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI

struct EmotionalTranscriptView: View {
    @ObservedObject var viewModel: EmotionAnalysisViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Transcript")
                    .font(.title)
                    .padding(.top)
                
                ForEach(viewModel.sentences) { sentence in
                    Text(sentence.text)
                        .padding()
                        .background(dominantEmotionColor(for: sentence))
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    
    func dominantEmotionColor(for sentence: Sentence) -> Color {
        guard let dominant = viewModel.getDominantEmotion(for: sentence) else {
            return .gray.opacity(0.1)
        }
        return emotionColor(for: dominant.name).opacity(0.2)
    }
}
