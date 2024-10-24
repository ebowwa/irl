//
//  AudioPlaybackManager.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/23/24.
//
// AudioPlaybackManager.swift
// openaudiostandard

import Foundation
import AVFoundation
import Combine

public class AudioPlaybackManager: NSObject, AVAudioPlayerDelegate, ObservableObject {
    
    // MARK: - Singleton Instance
    
    /// Shared instance of AudioPlaybackManager for global access.
    public static let shared = AudioPlaybackManager()
    
    // MARK: - Published Properties
    
    @Published public private(set) var isPlaying: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var audioPlayer: AVAudioPlayer?
    
    // MARK: - Initialization
    
    public override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Starts playback for a given audio file URL.
    /// - Parameter url: The URL of the audio file to play.
    public func startPlayback(for url: URL?) {
        guard let url = url else {
            errorMessage = "Invalid audio URL."
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            errorMessage = "Error starting playback: \(error.localizedDescription)"
            print("AudioPlaybackManager Error: \(error.localizedDescription)")
        }
    }
    
    /// Pauses the current audio playback.
    public func pausePlayback() {
        guard isPlaying else { return }
        audioPlayer?.pause()
        isPlaying = false
    }
    
    // MARK: - AVAudioPlayerDelegate Methods
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            if !flag {
                self?.errorMessage = "Playback did not finish successfully."
            }
        }
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Playback decode error: \(error.localizedDescription)"
                self?.isPlaying = false
            }
        }
    }
}
