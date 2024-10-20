//
//  SNROptimizer.swift
//  IRL
//
//  Created by Elijah Arbee on 10/15/24.
//


//
//  SNROptimizer.swift
//  irl
//
//  Created by Elijah Arbee on 10/15/24.
//

import Foundation

/// A utility for optimizing Signal-to-Noise Ratio (SNR) in audio processing.
public struct SNROptimizer {
    private var signalPower: Double = 0.0
    private var noisePower: Double = 0.0
    
    /// Updates the optimizer with a new audio sample.
    /// - Parameter sample: The audio sample to process.
    public mutating func update(with sample: Float) {
        let signal = Double(sample)
        signalPower += signal * signal
        noisePower += 1.0 // Assuming noise power estimation is handled separately
    }
    
    /// Calculates the current Signal-to-Noise Ratio (SNR).
    /// - Returns: The calculated SNR in decibels (dB).
    public func calculateSNR() -> Double {
        guard noisePower != 0 else { return 0.0 }
        return 10 * log10(signalPower / noisePower)
    }
}
