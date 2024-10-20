//
//  KalmanFilter.swift
//  IRL
//
//  Created by Elijah Arbee on 10/15/24.
//


//
//  KalmanFilter.swift
//  irl
//
//  Created by Elijah Arbee on 10/15/24.
//

import Foundation

/// A Kalman Filter implementation for noise reduction in audio signals.
public struct KalmanFilter {
    private var q: Double // Process noise covariance
    private var r: Double // Measurement noise covariance
    private var x: Double // Estimated signal
    private var p: Double // Estimated error covariance
    private var k: Double // Kalman Gain
    
    /// Initializes the Kalman Filter with specified parameters.
    /// - Parameters:
    ///   - processNoise: The process noise covariance.
    ///   - measurementNoise: The measurement noise covariance.
    ///   - initialEstimate: The initial estimate of the signal.
    ///   - initialErrorCovariance: The initial error covariance.
    public init(processNoise: Double, measurementNoise: Double, initialEstimate: Double, initialErrorCovariance: Double) {
        self.q = processNoise
        self.r = measurementNoise
        self.x = initialEstimate
        self.p = initialErrorCovariance
        self.k = 0.0
    }
    
    /// Updates the filter with a new measurement and returns the estimated signal.
    /// - Parameter measurement: The new measurement.
    /// - Returns: The estimated signal after filtering.
    public mutating func update(measurement: Double) -> Double {
        // Prediction
        p += q
        
        // Update
        k = p / (p + r)
        x += k * (measurement - x)
        p *= (1 - k)
        
        return x
    }
}
