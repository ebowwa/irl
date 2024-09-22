//
//  EmotionParser.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//
import Foundation

class EmotionParser {
    static func loadEmotionsFromJSON() -> [EmotionDimension] {
        guard let url = Bundle.main.url(forResource: "emotions", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Error loading emotions JSON file")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let emotionsData = try decoder.decode(EmotionsData.self, from: data)
            return emotionsData.emotions
        } catch {
            print("Error decoding emotions JSON: \(error)")
            return []
        }
    }
    
    static func loadPredictionsData() -> [[String: Any]]? {
        guard let url = Bundle.main.url(forResource: "EmotionPredictionDemo", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Error loading JSON file")
            return nil
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
                print("Error: Root is not an array")
                return nil
            }
            return json
        } catch {
            print("Error parsing JSON: \(error)")
            return nil
        }
    }
    
    static func parseEmotions(_ emotionsData: [[String: Any]]) -> [Emotion] {
        emotionsData.compactMap { emotionDict in
            guard let name = emotionDict["name"] as? String,
                  let score = emotionDict["score"] as? Double else {
                return nil
            }
            return Emotion(name: name, score: score)
        }
    }
}
