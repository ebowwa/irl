//
//  EmotionAnalyzer.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import Foundation

class EmotionAnalyzer {
    static func calculateOverallEmotions(from sentences: [Sentence]) -> [MainEmotion] {
        var emotionScores: [String: [Double]] = [:]
        
        for sentence in sentences {
            for emotion in sentence.emotions {
                emotionScores[emotion.name, default: []].append(emotion.score)
            }
        }
        
        return emotionScores.map { (name, scores) in
            let avgScore = scores.reduce(0, +) / Double(scores.count)
            return MainEmotion(name: name, score: avgScore)
        }.sorted { $0.score > $1.score }
    }
    
    static func categorizeEmotions(_ overallEmotions: [MainEmotion], allEmotions: [EmotionDimension]) -> [EmotionCategory: [MainEmotion]] {
        var emotionsByCategory: [EmotionCategory: [MainEmotion]] = [:]
        
        for category in EmotionCategory.allCases {
            let categoryEmotions = overallEmotions.filter { emotion in
                allEmotions.first { $0.name == emotion.name }?.categories.contains(category.rawValue) ?? false
            }
            emotionsByCategory[category] = categoryEmotions.sorted { $0.score > $1.score }
        }
        
        return emotionsByCategory
    }
    
    static func getEmotionTimeline(sentences: [Sentence]) -> [(Int, [MainEmotion])] {
        sentences.enumerated().map { (index, sentence) in
            (index, sentence.emotions.sorted { $0.score > $1.score })
        }
    }
    
    static func getEmotionTimeline(sentences: [Sentence], for category: EmotionCategory) -> [(Int, [MainEmotion])] {
        sentences
            .filter { $0.category == category }
            .enumerated()
            .map { (index, sentence) in
                (index, sentence.emotions.sorted { $0.score > $1.score })
            }
    }
    
    static func getDominantEmotion(for sentence: Sentence) -> MainEmotion? {
        sentence.emotions.max { $0.score < $1.score }
    }
    
    static func getAverageEmotionIntensity(emotions: [MainEmotion]) -> Double {
        let totalIntensity = emotions.reduce(0) { $0 + $1.score }
        return totalIntensity / Double(emotions.count)
    }
    
    static func getEmotionFrequency(emotion: String, in sentences: [Sentence]) -> Double {
        let emotionAppearances = sentences.filter { sentence in
            sentence.emotions.contains { $0.name == emotion }
        }.count
        return Double(emotionAppearances) / Double(sentences.count)
    }
    
    static func getMostFrequentEmotion(in sentences: [Sentence], overallEmotions: [MainEmotion]) -> String? {
        overallEmotions.max { a, b in
            getEmotionFrequency(emotion: a.name, in: sentences) < getEmotionFrequency(emotion: b.name, in: sentences)
        }?.name
    }
    
    static func getEmotionVariability(emotions: [MainEmotion]) -> Double {
        let meanScore = emotions.reduce(0) { $0 + $1.score } / Double(emotions.count)
        let sumSquaredDifferences = emotions.reduce(0) { $0 + pow($1.score - meanScore, 2) }
        return sqrt(sumSquaredDifferences / Double(emotions.count))
    }
    
    static func getEmotionalShifts(in sentences: [Sentence]) -> [(String, String, Int)] {
        var shifts: [(String, String, Int)] = []
        for i in 1..<sentences.count {
            let prevDominant = getDominantEmotion(for: sentences[i-1])?.name ?? ""
            let currentDominant = getDominantEmotion(for: sentences[i])?.name ?? ""
            if prevDominant != currentDominant {
                shifts.append((prevDominant, currentDominant, i))
            }
        }
        return shifts
    }
    
    static func getEmotionCoOccurrences(in sentences: [Sentence]) -> [(String, String, Int)] {
        var coOccurrences: [String: [String: Int]] = [:]
        for sentence in sentences {
            let topEmotions = sentence.emotions.sorted { $0.score > $1.score }.prefix(3).map { $0.name }
            for i in 0..<topEmotions.count {
                for j in (i+1)..<topEmotions.count {
                    let (emotion1, emotion2) = (topEmotions[i], topEmotions[j])
                    coOccurrences[emotion1, default: [:]][emotion2, default: 0] += 1
                    coOccurrences[emotion2, default: [:]][emotion1, default: 0] += 1
                }
            }
        }
        
        return coOccurrences.flatMap { (emotion1, occurrences) in
            occurrences.map { (emotion2, count) in
                (emotion1, emotion2, count)
            }
        }.sorted { $0.2 > $1.2 }
    }
}
