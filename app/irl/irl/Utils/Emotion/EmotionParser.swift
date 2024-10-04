//
//  EmotionParser.swift
//  irl
//
//  Created by Elijah Arbee on 9/10/24.
//

import Foundation

class EmotionParser {
    // Function to load emotions from JSON and return [EmotionDimension]
    static func loadEmotionsFromJSON() -> [EmotionDimension] {
        guard let url = Bundle.main.url(forResource: "emotions", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Error loading emotions JSON file")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let availableEmotions = try decoder.decode(AvailableEmotions.self, from: data)
            return availableEmotions.emotions
        } catch {
            print("Error decoding emotions JSON: \(error)")
            return []
        }
    }
    
    // Function to load predictions data from JSON and return [[String: Any]]?
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
    
    // Function to parse emotions from [[String: Any]] and return [MainEmotion]
    static func parseEmotions(_ emotionsData: [[String: Any]]) -> [MainEmotion] {
        emotionsData.compactMap { emotionDict in
            guard let name = emotionDict["name"] as? String,
                  let score = emotionDict["score"] as? Double else {
                return nil
            }
            return MainEmotion(name: name, score: score)
        }
    }
}
