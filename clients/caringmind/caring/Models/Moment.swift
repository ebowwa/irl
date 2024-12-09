import Foundation

struct Moment: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let category: String
    var metadata: [String: Any]
    var interactions: [String: Any]
    var tags: [String]
    
    private enum CodingKeys: String, CodingKey {
        case id, timestamp, category, metadata, interactions, tags
    }
    
    init(id: UUID = UUID(), timestamp: Date = Date(), category: String, metadata: [String: Any], interactions: [String: Any] = [:], tags: [String] = []) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.metadata = metadata
        self.interactions = interactions
        self.tags = tags
    }
    
    // MARK: - Codable Implementation
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        category = try container.decode(String.self, forKey: .category)
        tags = try container.decode([String].self, forKey: .tags)
        
        let metadataData = try container.decode(Data.self, forKey: .metadata)
        metadata = (try JSONSerialization.jsonObject(with: metadataData) as? [String: Any]) ?? [:]
        
        let interactionsData = try container.decode(Data.self, forKey: .interactions)
        interactions = (try JSONSerialization.jsonObject(with: interactionsData) as? [String: Any]) ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encode(tags, forKey: .tags)
        
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        try container.encode(metadataData, forKey: .metadata)
        
        let interactionsData = try JSONSerialization.data(withJSONObject: interactions)
        try container.encode(interactionsData, forKey: .interactions)
    }
    
    // MARK: - Voice Analysis // rename to Name Input 
    
    static func voiceAnalysis(
        name: String,
        prosody: String,
        feeling: String,
        confidenceScore: Int,
        analysis: String,
        extraData: [String: Any] = [:]
    ) -> Moment {
        var metadata: [String: Any] = [
            "name": name,
            "prosody": prosody,
            "feeling": feeling,
            "confidence_score": confidenceScore,
            "analysis": analysis
        ]
        metadata.merge(extraData) { (_, new) in new }
        
        return Moment(
            category: "voice_analysis",
            metadata: metadata,
            tags: ["voice", feeling.lowercased()]
        )
    }
}