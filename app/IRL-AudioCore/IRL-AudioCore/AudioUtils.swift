//
//  AudioUtils.swift
//  IRL-AudioCore
//
//  Created by Elijah Arbee on 10/20/24.
//


//
//  AudioUtils.swift
//  AudioFramework
//
//  Created by Elijah Arbee on 10/11/24.
//

import Foundation

public struct AudioUtils {
    /// Normalizes audio level from decibels to a range between 0 and 1
    public static func normalizeAudioLevel(_ level: Float) -> Double {
        let minDb: Float = -80.0
        let maxDb: Float = 0.0
        let clampedLevel = max(min(level, maxDb), minDb)
        return Double((clampedLevel - minDb) / (maxDb - minDb))
    }
}
