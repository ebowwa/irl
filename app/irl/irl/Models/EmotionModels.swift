import Foundation

// MARK: - AvailableEmotions
struct AvailableEmotions: Codable {
    let emotions: [EmotionDimension]
}

struct EmotionDimension: Codable {
    let name: String
    let categories: [String]
}

struct Sentence: Identifiable {
    let id = UUID()
    let text: String
    let emotions: [MainEmotion]
    let words: [Word]
    let category: EmotionCategory
}

struct Word: Identifiable {
    let id = UUID()
    let text: String
    let emotions: [MainEmotion]
}

struct MainEmotion: Identifiable, Codable {
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


//
//  HumeEmotionalPredictionResultsModel.swift
//  irl
//
//  Created by Elijah Arbee on 10/4/24.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let welcome = try? JSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

// MARK: - WelcomeElement
class WelcomeElement: Codable {
    let source: Source
    let results: Results

    init(source: Source, results: Results) {
        self.source = source
        self.results = results
    }
}

// MARK: - Results
class Results: Codable {
    let predictions: [ResultsPrediction]
    let errors: [JSONAny]

    init(predictions: [ResultsPrediction], errors: [JSONAny]) {
        self.predictions = predictions
        self.errors = errors
    }
}

// MARK: - ResultsPrediction
class ResultsPrediction: Codable {
    let file: String
    let models: Models

    init(file: String, models: Models) {
        self.file = file
        self.models = models
    }
}

// MARK: - Models
class Models: Codable {
    let burst, prosody, language, ner: Burst

    init(burst: Burst, prosody: Burst, language: Burst, ner: Burst) {
        self.burst = burst
        self.prosody = prosody
        self.language = language
        self.ner = ner
    }
}

// MARK: - Burst
class Burst: Codable {
    let metadata: Metadata?
    let groupedPredictions: [GroupedPrediction]

    enum CodingKeys: String, CodingKey {
        case metadata
        case groupedPredictions = "grouped_predictions"
    }

    init(metadata: Metadata?, groupedPredictions: [GroupedPrediction]) {
        self.metadata = metadata
        self.groupedPredictions = groupedPredictions
    }
}

// MARK: - GroupedPrediction
class GroupedPrediction: Codable {
    let id: String
    let predictions: [GroupedPredictionPrediction]

    init(id: String, predictions: [GroupedPredictionPrediction]) {
        self.id = id
        self.predictions = predictions
    }
}

// MARK: - GroupedPredictionPrediction
class GroupedPredictionPrediction: Codable {
    let text: String
    let time: Position
    let confidence: Double
    let emotions: [JSONEmotion]
    let sentiment, toxicity: JSONNull?
    let position: Position?
    let speakerConfidence: JSONNull?

    enum CodingKeys: String, CodingKey {
        case text, time, confidence, emotions, sentiment, toxicity, position
        case speakerConfidence = "speaker_confidence"
    }

    init(text: String, time: Position, confidence: Double, emotions: [JSONEmotion], sentiment: JSONNull?, toxicity: JSONNull?, position: Position?, speakerConfidence: JSONNull?) {
        self.text = text
        self.time = time
        self.confidence = confidence
        self.emotions = emotions
        self.sentiment = sentiment
        self.toxicity = toxicity
        self.position = position
        self.speakerConfidence = speakerConfidence
    }
}

// MARK: - JSONEmotion
struct JSONEmotion: Codable {
    let name: String
    let score: Double
}

// MARK: - Position
struct Position: Codable {
    let begin, end: Double
}

struct Metadata: Codable {
    let confidence: Double
    let detectedLanguage: String

    enum CodingKeys: String, CodingKey {
        case confidence
        case detectedLanguage = "detected_language"
    }

    init(confidence: Double, detectedLanguage: String) {
        self.confidence = confidence
        self.detectedLanguage = detectedLanguage
    }
}

struct Source: Codable {
    let type, filename, contentType, md5Sum: String

    enum CodingKeys: String, CodingKey {
        case type, filename
        case contentType = "content_type"
        case md5Sum = "md5sum"
    }

    init(type: String, filename: String, contentType: String, md5Sum: String) {
        self.type = type
        self.filename = filename
        self.contentType = contentType
        self.md5Sum = md5Sum
    }
}

typealias Welcome = [WelcomeElement]

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
            return true
    }

    public var hashValue: Int {
            return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if !container.decodeNil() {
                    throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
            }
    }

    public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
    }
}

struct JSONCodingKey: CodingKey {
    let key: String

    init?(intValue: Int) {
            return nil
    }

    init?(stringValue: String) {
            key = stringValue
    }

    var intValue: Int? {
            return nil
    }

    var stringValue: String {
            return key
    }
}

struct JSONAny: Codable {

    let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
            return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
            return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
            if let value = try? container.decode(Bool.self) {
                    return value
            }
            if let value = try? container.decode(Int64.self) {
                    return value
            }
            if let value = try? container.decode(Double.self) {
                    return value
            }
            if let value = try? container.decode(String.self) {
                    return value
            }
            if container.decodeNil() {
                    return JSONNull()
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
            if let value = try? container.decode(Bool.self) {
                    return value
            }
            if let value = try? container.decode(Int64.self) {
                    return value
            }
            if let value = try? container.decode(Double.self) {
                    return value
            }
            if let value = try? container.decode(String.self) {
                    return value
            }
            if let value = try? container.decodeNil() {
                    if value {
                            return JSONNull()
                    }
            }
            if var container = try? container.nestedUnkeyedContainer() {
                    return try decodeArray(from: &container)
            }
            if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
                    return try decodeDictionary(from: &container)
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey) throws -> Any {
            if let value = try? container.decode(Bool.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(Int64.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(Double.self, forKey: key) {
                    return value
            }
            if let value = try? container.decode(String.self, forKey: key) {
                    return value
            }
            if let value = try? container.decodeNil(forKey: key) {
                    if value {
                            return JSONNull()
                    }
            }
            if var container = try? container.nestedUnkeyedContainer(forKey: key) {
                    return try decodeArray(from: &container)
            }
            if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key) {
                    return try decodeDictionary(from: &container)
            }
            throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
            var arr: [Any] = []
            while !container.isAtEnd {
                    let value = try decode(from: &container)
                    arr.append(value)
            }
            return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws -> [String: Any] {
            var dict = [String: Any]()
            for key in container.allKeys {
                    let value = try decode(from: &container, forKey: key)
                    dict[key.stringValue] = value
            }
            return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
            for value in array {
                    if let value = value as? Bool {
                            try container.encode(value)
                    } else if let value = value as? Int64 {
                            try container.encode(value)
                    } else if let value = value as? Double {
                            try container.encode(value)
                    } else if let value = value as? String {
                            try container.encode(value)
                    } else if value is JSONNull {
                            try container.encodeNil()
                    } else if let value = value as? [Any] {
                            var container = container.nestedUnkeyedContainer()
                            try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                            var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                            try encode(to: &container, dictionary: value)
                    } else {
                            throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
            }
    }

    static func encode(to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]) throws {
            for (key, value) in dictionary {
                    let key = JSONCodingKey(stringValue: key)!
                    if let value = value as? Bool {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? Int64 {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? Double {
                            try container.encode(value, forKey: key)
                    } else if let value = value as? String {
                            try container.encode(value, forKey: key)
                    } else if value is JSONNull {
                            try container.encodeNil(forKey: key)
                    } else if let value = value as? [Any] {
                            var container = container.nestedUnkeyedContainer(forKey: key)
                            try encode(to: &container, array: value)
                    } else if let value = value as? [String: Any] {
                            var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                            try encode(to: &container, dictionary: value)
                    } else {
                            throw encodingError(forValue: value, codingPath: container.codingPath)
                    }
            }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
            if let value = value as? Bool {
                    try container.encode(value)
            } else if let value = value as? Int64 {
                    try container.encode(value)
            } else if let value = value as? Double {
                    try container.encode(value)
            } else if let value = value as? String {
                    try container.encode(value)
            } else if value is JSONNull {
                    try container.encodeNil()
            } else {
                    throw encodingError(forValue: value, codingPath: container.codingPath)
            }
    }

    public init(from decoder: Decoder) throws {
            if var arrayContainer = try? decoder.unkeyedContainer() {
                    self.value = try JSONAny.decodeArray(from: &arrayContainer)
            } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
                    self.value = try JSONAny.decodeDictionary(from: &container)
            } else {
                    let container = try decoder.singleValueContainer()
                    self.value = try JSONAny.decode(from: container)
            }
    }

    public func encode(to encoder: Encoder) throws {
            if let arr = self.value as? [Any] {
                    var container = encoder.unkeyedContainer()
                    try JSONAny.encode(to: &container, array: arr)
            } else if let dict = self.value as? [String: Any] {
                    var container = encoder.container(keyedBy: JSONCodingKey.self)
                    try JSONAny.encode(to: &container, dictionary: dict)
            } else {
                    var container = encoder.singleValueContainer()
                    try JSONAny.encode(to: &container, value: self.value)
            }
    }
}
