//
//  DetailAnalysisView.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI
import Charts

struct DetailedAnalysisView: View {
    @ObservedObject var viewModel: EmotionAnalysisViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.sentences) { sentence in
                Section(header: Text(sentence.text)) {
                    EmotionChartView(emotions: sentence.emotions)
                        .frame(height: 200)
                    
                    ForEach(sentence.words) { word in
                        DisclosureGroup(word.text) {
                            ForEach(word.emotions.filter { $0.score > 0.1 }) { emotion in
                                EmotionBarView(emotion: emotion, compact: true)
                            }
                        }
                    }
                }
            }
        }
    }
}
