/**
//  TranscriptEntry.swift
//   CaringMind
//
//  Created by Elijah Arbee on 11/9/24.
//

import Foundation

// MARK: - TranscriptEntry Model

/// Represents a single entry in the transcript with relevant metadata.
struct TranscriptEntry: Identifiable, Codable {
    let id: UUID  // Unique identifier for each transcript entry
    let text: String  // The transcribed text
    let timestamp: Date  // The date and time when the entry was created
    let startTime: TimeInterval  // Start time of the speech segment
    let endTime: TimeInterval  // End time of the speech segment
    let sequenceNumber: Int  // Sequential number of the transcript entry

    /// Returns the timestamp in "HH:mm:ss" format.
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }

    /// Calculates the duration of the speech segment.
    var duration: TimeInterval {
        return endTime - startTime
    }

    // Initialize with a new UUID if not provided during decoding
    init(
        id: UUID = UUID(), text: String, timestamp: Date, startTime: TimeInterval,
        endTime: TimeInterval, sequenceNumber: Int
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.startTime = startTime
        self.endTime = endTime
        self.sequenceNumber = sequenceNumber
    }

    // MARK: - Codable Conformance

    enum CodingKeys: String, CodingKey {
        case text, timestamp, startTime, endTime, sequenceNumber
        // Exclude 'id' from coding keys to prevent decoding it
    }

    /// Custom initializer to decode without `id`
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.startTime = try container.decode(TimeInterval.self, forKey: .startTime)
        self.endTime = try container.decode(TimeInterval.self, forKey: .endTime)
        self.sequenceNumber = try container.decode(Int.self, forKey: .sequenceNumber)
        self.id = UUID()  // Assign a new UUID during decoding
    }

    /// Custom encoder to exclude `id`
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(sequenceNumber, forKey: .sequenceNumber)
        // 'id' is not encoded
    }
}

// MARK: - Equatable Conformance

extension TranscriptEntry: Equatable {
    static func == (lhs: TranscriptEntry, rhs: TranscriptEntry) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.timestamp == rhs.timestamp &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               lhs.sequenceNumber == rhs.sequenceNumber
    }
}

*/
