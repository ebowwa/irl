//
//  OverviewView.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI
import Charts

struct OverviewView: View {
    @ObservedObject var viewModel: EmotionAnalysisViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Emotion Overview")
                    .font(.title)
                    .padding(.top)
                
                EmotionChartView(emotions: viewModel.overallEmotions)
                    .frame(height: 300)
                
                Text("Top 5 Emotions")
                    .font(.headline)
                ForEach(viewModel.getTopEmotions()) { emotion in
                    EmotionBarView(emotion: emotion)
                }
                
                Text("Emotion Timeline")
                    .font(.headline)
                EmotionTimelineView(timeline: viewModel.getEmotionTimeline())
                    .frame(height: 300)
            }
            .padding()
        }
    }
}
