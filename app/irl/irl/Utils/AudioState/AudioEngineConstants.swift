//
//  AudioEngineService.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//  Updated by OpenAI on 10/17/24.
//

import Foundation
import AVFoundation
import Combine
import Accelerate

// MARK: - Constants
private enum AudioEngineConstants {
    static let bufferSize: AVAudioFrameCount = 1024
    static let maxFrameCount: AVAudioFrameCount = 4096 // for manual rendering
}

// MARK: - AudioEngineService
class AudioEngineService: ObservableObject {
    static let shared = AudioEngineService()
    
    // MARK: - Published Properties
    @Published var currentAudioLevel: Double = 0.0
    @Published var currentAudioInputSource: String = "Unknown"
    @Published var manualRenderingMode: AVAudioEngineManualRenderingMode = .realtime // Default mode
    
    // MARK: - Private Properties
    let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    private var cancellables: Set<AnyCancellable> = []
    private var renderingStatus: AVAudioEngineManualRenderingStatus = .success
    
    // MARK: - Publishers
    let audioBufferPublisher = PassthroughSubject<AVAudioPCMBuffer, Never>()
    let audioLevelPublisher = PassthroughSubject<Float, Never>()
    
    // MARK: - Audio Engine Control
    func startAudioEngine(in mode: AVAudioEngineManualRenderingMode = .realtime) {
        setupAudioSession()
        detectAudioInputSource() // Detect the audio source initially
        
        manualRenderingMode = mode
        configureRenderingMode()

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Tap the audio input for processing
        inputNode.installTap(onBus: 0, bufferSize: AudioEngineConstants.bufferSize, format: recordingFormat) { [weak self] buffer, when in
            guard let self = self else { return }
            // Publish the audio buffer
            self.audioBufferPublisher.send(buffer)
            // Calculate audio level and publish
            let level = self.calculateAudioLevel(from: buffer)
            self.audioLevelPublisher.send(level)
        }
        
        do {
            audioEngine.prepare()
            try audioEngine.start()
            print("Audio Engine started.")
            print("Audio Input Source: \(currentAudioInputSource)")
        } catch {
            print("Audio Engine couldn't start: \(error.localizedDescription)")
        }
    }
    
    func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            do {
                try audioSession.setActive(false)
            } catch {
                print("Audio Session couldn't be deactivated: \(error.localizedDescription)")
            }
            print("Audio Engine stopped.")
        }
    }
    
    // MARK: - Manual Rendering Mode Setup
    private func configureRenderingMode() {
        guard audioEngine.isRunning == false else {
            print("Engine must be stopped before enabling manual rendering mode.")
            return
        }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        do {
            try audioEngine.enableManualRenderingMode(manualRenderingMode, format: format, maximumFrameCount: AudioEngineConstants.maxFrameCount)
            print("Manual rendering mode enabled: \(manualRenderingMode)")
        } catch {
            print("Failed to enable manual rendering mode: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Audio Input Source Detection
    private func detectAudioInputSource() {
        let currentRoute = audioSession.currentRoute
        if let inputPort = currentRoute.inputs.first {
            currentAudioInputSource = inputPort.portName
        } else {
            currentAudioInputSource = "No input detected"
        }
        
        // Print the detected source
        print("Detected audio input source: \(currentAudioInputSource)")
    }
    
    // MARK: - Audio Level Calculation
    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> Float {
        let frameLength = Int(buffer.frameLength)
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }
        
        var rms: Float = 0.0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))
        
        // Convert to a linear scale (0.0 - 1.0)
        return rms
    }
    
    // MARK: - Manual Rendering Handler
    func renderManualMode() {
        guard audioEngine.isInManualRenderingMode else {
            print("Engine is not in manual rendering mode.")
            return
        }
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioEngine.manualRenderingFormat, frameCapacity: AudioEngineConstants.maxFrameCount)!
        
        do {
            renderingStatus = try audioEngine.renderOffline(AudioEngineConstants.maxFrameCount, to: buffer)
            
            switch renderingStatus {
            case .success:
                print("Rendering successful. Data rendered to buffer.")
                audioBufferPublisher.send(buffer)
            case .insufficientDataFromInputNode:
                print("Insufficient data from input node during rendering.")
            case .cannotDoInCurrentContext:
                print("Rendering cannot be performed in the current context.")
            case .error:
                print("An error occurred during rendering.")
            @unknown default:
                print("Unknown rendering status.")
            }
            
        } catch {
            print("Failed to render in manual mode: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Handling Errors
    private func handleRenderingError(_ error: AVAudioEngineManualRenderingError) {
        switch error {
        case .invalidMode:
            print("Engine is not in manual rendering mode or the wrong mode is being used.")
        case .initialized:
            print("Cannot perform operation because the engine is initialized (not stopped).")
        case .notRunning:
            print("Cannot perform operation because the engine is not running.")
        @unknown default:
            print("An unknown error occurred in manual rendering.")
        }
    }
}
