//
//  EmotionAnalysisViewModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI

class EmotionAnalysisViewModel: ObservableObject {
    @Published var sentences: [Sentence] = []
    @Published var overallEmotions: [MainEmotion] = []
    @Published var emotionsByCategory: [EmotionCategory: [MainEmotion]] = [:]
    
    private var allEmotions: [EmotionDimension] = []
    
    init() {
        loadEmotionsFromJSON()
        loadData()
    }
    
    private func loadEmotionsFromJSON() {
        self.allEmotions = EmotionParser.loadEmotionsFromJSON()
    }
    
    func loadData() {
        guard let json = EmotionParser.loadPredictionsData() else { return }
        
        for item in json {
            parseItem(item)
        }
        
        overallEmotions = EmotionAnalyzer.calculateOverallEmotions(from: sentences)
        emotionsByCategory = EmotionAnalyzer.categorizeEmotions(overallEmotions, allEmotions: allEmotions)
    }
    
    private func parseItem(_ item: [String: Any]) {
        guard let results = item["results"] as? [String: Any],
              let predictions = results["predictions"] as? [[String: Any]] else {
            print("Error: Unable to find predictions")
            return
        }
        
        for prediction in predictions {
            parsePrediction(prediction)
        }
    }
    
    private func parsePrediction(_ prediction: [String: Any]) {
        guard let models = prediction["models"] as? [String: Any] else {
            print("Error: Unable to find models")
            return
        }
        
        if let prosody = models["prosody"] as? [String: Any] {
            parseModelPredictions(prosody, category: .speechProsody)
        }
        
        if let vocalBurst = models["vocal_burst"] as? [String: Any] {
            parseModelPredictions(vocalBurst, category: .vocalBurst)
        }
        
        if let language = models["language"] as? [String: Any] {
            parseModelPredictions(language, category: .language)
        }
        
        if let facial = models["facial"] as? [String: Any] {
            parseModelPredictions(facial, category: .facialExpression)
        }
    }
    
    private func parseModelPredictions(_ modelData: [String: Any], category: EmotionCategory) {
        guard let groupedPredictions = modelData["grouped_predictions"] as? [[String: Any]] else {
            print("Error: Unable to find grouped_predictions for \(category)")
            return
        }
        
        for group in groupedPredictions {
            parseGroup(group, category: category)
        }
    }
    
    private func parseGroup(_ group: [String: Any], category: EmotionCategory) {
        guard let predictions = group["predictions"] as? [[String: Any]] else {
            print("Error: Unable to find predictions in group for \(category)")
            return
        }
        
        for prediction in predictions {
            if let text = prediction["text"] as? String,
               let emotionsData = prediction["emotions"] as? [[String: Any]] {
                let emotions = EmotionParser.parseEmotions(emotionsData)
                let words = text.split(separator: " ").map { Word(text: String($0), emotions: emotions) }
                sentences.append(Sentence(text: text, emotions: emotions, words: words, category: category))
            }
        }
    }
    
    func getTopEmotions(count: Int = 5) -> [MainEmotion] {
        Array(overallEmotions.prefix(count))
    }
    
    func getTopEmotions(for category: EmotionCategory, count: Int = 5) -> [MainEmotion] {
        Array((emotionsByCategory[category] ?? []).prefix(count))
    }
    
    func getEmotionTimeline() -> [(Int, [MainEmotion])] {
        EmotionAnalyzer.getEmotionTimeline(sentences: sentences)
    }
    
    func getEmotionTimeline(for category: EmotionCategory) -> [(Int, [MainEmotion])] {
        EmotionAnalyzer.getEmotionTimeline(sentences: sentences, for: category)
    }
    
    func getDominantEmotion(for sentence: Sentence) -> MainEmotion? {
        EmotionAnalyzer.getDominantEmotion(for: sentence)
    }
    
    func getAverageEmotionIntensity() -> Double {
        EmotionAnalyzer.getAverageEmotionIntensity(emotions: overallEmotions)
    }
    
    func getAverageEmotionIntensity(for category: EmotionCategory) -> Double {
        guard let categoryEmotions = emotionsByCategory[category] else {
            return 0
        }
        return EmotionAnalyzer.getAverageEmotionIntensity(emotions: categoryEmotions)
    }
    
    func getEmotionFrequency(emotion: String) -> Double {
        EmotionAnalyzer.getEmotionFrequency(emotion: emotion, in: sentences)
    }
    
    func getMostFrequentEmotion() -> String? {
        EmotionAnalyzer.getMostFrequentEmotion(in: sentences, overallEmotions: overallEmotions)
    }
    
    func getEmotionVariability() -> Double {
        EmotionAnalyzer.getEmotionVariability(emotions: overallEmotions)
    }
    
    func getEmotionalShifts() -> [(String, String, Int)] {
        EmotionAnalyzer.getEmotionalShifts(in: sentences)
    }
    
    func getEmotionCoOccurrences() -> [(String, String, Int)] {
        EmotionAnalyzer.getEmotionCoOccurrences(in: sentences)
    }
    
    // MARK: - Utility Functions
    
    /// Calculates the linear trend (slope and intercept) of emotion scores over time.
    func detectEmotionTrend() -> (slope: Double, intercept: Double)? {
        let emotionTimeline = getEmotionTimeline()
        let n = Double(emotionTimeline.count)
        
        guard n > 1 else { return nil }
        
        // Extract x (time indices) and y (emotion scores) values
        let xValues = emotionTimeline.map { Double($0.0) }
        let yValues = emotionTimeline.map { $0.1.first?.score ?? 0.0 }
        
        let sumX = xValues.reduce(0, +)
        let sumY = yValues.reduce(0, +)
        let sumXY = zip(xValues, yValues).reduce(0) { $0 + $1.0 * $1.1 }
        let sumXX = xValues.reduce(0) { $0 + $1 * $1 }
        
        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return nil }
        
        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n
        
        return (slope, intercept)
    }
    
    /// Calculates the standard deviation of emotion scores.
    func calculateEmotionStandardDeviation() -> Double {
        let scores = overallEmotions.map { $0.score }
        let count = Double(scores.count)
        
        guard count > 0 else { return 0.0 }
        
        let mean = scores.reduce(0, +) / count
        let variance = scores.reduce(0) { $0 + pow($1 - mean, 2) } / count
        return sqrt(variance)
    }
}
