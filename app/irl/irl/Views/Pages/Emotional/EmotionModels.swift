import Foundation

struct EmotionsData: Codable {
    let emotions: [EmotionDimension]
}

struct EmotionDimension: Codable {
    let name: String
    let categories: [String]
}

struct Sentence: Identifiable {
    let id = UUID()
    let text: String
    let emotions: [Emotion]
    let words: [Word]
    let category: EmotionCategory
}

struct Word: Identifiable {
    let id = UUID()
    let text: String
    let emotions: [Emotion]
}

struct Emotion: Identifiable {
    let id = UUID()
    let name: String
    let score: Double
}

enum EmotionCategory: String, CaseIterable, Codable {
    case language
    case facialExpression
    case vocalBurst
    case speechProsody
}
