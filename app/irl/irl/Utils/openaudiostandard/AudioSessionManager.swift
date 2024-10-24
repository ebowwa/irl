//
//  AudioSessionManager.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/23/24.
//


// AudioSessionManager.swift
import Foundation
import AVFoundation

public class AudioSessionManager {
    
    public static let shared = AudioSessionManager()
    
    private let session = AVAudioSession.sharedInstance()
    
    private init() {}
    
    public func setupSession(caller: String = #function) {
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("[AudioSessionManager] \(caller) - Audio session successfully set up.")
        } catch {
            print("[AudioSessionManager] \(caller) - Failed to set up audio session: \(error.localizedDescription)")
        }
    }
}
