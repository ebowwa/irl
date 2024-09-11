//
//  EmotionAnalysisViewModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
//
//  EmotionAnalysisViewModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import SwiftUI

class EmotionAnalysisViewModel: ObservableObject {
    @Published var sentences: [Sentence] = []
    @Published var overallEmotions: [Emotion] = []
    @Published var emotionsByCategory: [EmotionCategory: [Emotion]] = [:]
    
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
    
    func getTopEmotions(count: Int = 5) -> [Emotion] {
        Array(overallEmotions.prefix(count))
    }
    
    func getTopEmotions(for category: EmotionCategory, count: Int = 5) -> [Emotion] {
        Array((emotionsByCategory[category] ?? []).prefix(count))
    }
    
    func getEmotionTimeline() -> [(Int, [Emotion])] {
        EmotionAnalyzer.getEmotionTimeline(sentences: sentences)
    }
    
    func getEmotionTimeline(for category: EmotionCategory) -> [(Int, [Emotion])] {
        EmotionAnalyzer.getEmotionTimeline(sentences: sentences, for: category)
    }
    
    func getDominantEmotion(for sentence: Sentence) -> Emotion? {
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
}
