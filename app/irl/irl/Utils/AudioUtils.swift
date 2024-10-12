//
//  AudioUtils.swift
//  IRL
//
//  Created by Elijah Arbee on 10/11/24.
//


import Foundation

struct AudioUtils {
    /// Normalizes the audio level from decibels to a value between 0 and 1.
    static func normalizeAudioLevel(_ level: Float) -> Double {
        let minDb: Float = -80.0
        let maxDb: Float = 0.0
        let clampedLevel = max(min(level, maxDb), minDb)
        return Double((clampedLevel - minDb) / (maxDb - minDb))
    }
}
