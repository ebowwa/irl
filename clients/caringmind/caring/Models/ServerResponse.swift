// TODO: this may be redundant i.e. this is redeclared from the moments and idk which is in use
import Foundation

struct ServerResponse: Codable {
    let name: String
    let prosody: String
    let feeling: String
    let confidence_score: Int
    let confidence_reasoning: String
    let psychoanalysis: String
    let location_background: String
    
    // Safe accessors with default values
    var safeName: String { name }
    var safeProsody: String { prosody }
    var safeFeeling: String { feeling }
    var safeConfidenceScore: Int { confidence_score }
    var safeConfidenceReasoning: String { confidence_reasoning }
    var safePsychoanalysis: String { psychoanalysis }
    var safeLocationBackground: String { location_background }
}

// Preview helper
extension ServerResponse {
    static let preview = ServerResponse(
        name: "Alex",
        prosody: "Confident and clear",
        feeling: "Positive",
        confidence_score: 85,
        confidence_reasoning: "Clear pronunciation and steady pace",
        psychoanalysis: "Shows self-assurance in voice",
        location_background: "Quiet environment"
    )
}
