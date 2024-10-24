//
//  AEngine.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/23/24.
//


import Foundation
import Combine
import AVFoundation

// MARK: - AudioEngineManager

public class AudioEngineManager: NSObject, AudioEngineManagerProtocol {
    public static let shared = AudioEngineManager()

    // MARK: - Subjects

    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    private let audioBufferSubject = PassthroughSubject<AVAudioPCMBuffer, Never>()
    public var audioBufferPublisher: AnyPublisher<AVAudioPCMBuffer, Never> {
        audioBufferSubject.eraseToAnyPublisher()
    }

    // MARK: - Properties

    public private(set) var isEngineRunning: Bool = false
    private let audioEngine = AVAudioEngine()
    private var webSocketManager: WebSocketManagerProtocol?

    private let audioBufferSize: AVAudioFrameCount = 1024
    private var isRecording: Bool = false
    private var audioFile: AVAudioFile?

    // MARK: - Initialization

    public override init() {
        super.init()
        setupAudioSession()
    }

    // MARK: - Audio Session Management

    private func setupAudioSession() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession.setActive(true)
            print("[AudioEngineManager] Audio session successfully set up.")
        } catch {
            print("[AudioEngineManager] Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - WebSocket Management

    public func assignWebSocketManager(manager: WebSocketManagerProtocol) {
        self.webSocketManager = manager
    }

    // MARK: - Engine Control

    public func startEngine() {
        guard !isEngineRunning else {
            print("[AudioEngineManager] Audio engine is already running.")
            return
        }
        installTapOnInputNode()
        startAudioEngine()
    }

    public func stopEngine() {
        guard isEngineRunning else {
            print("[AudioEngineManager] Audio engine is not running.")
            return
        }
        cleanupAudioEngine()
    }

    // MARK: - Recording Control

    public func startRecording() {
        guard !isRecording else {
            print("[AudioEngineManager] Already recording.")
            return
        }
        createAudioFile()
    }

    public func stopRecording() {
        guard isRecording else {
            print("[AudioEngineManager] Not currently recording.")
            return
        }
        finalizeRecording()
    }

    // MARK: - Audio Processing

    private func processAudioBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let channelData = buffer.floatChannelData else { return }
        let frames = buffer.frameLength

        sendAudioDataToWebSocket(buffer: buffer)
        audioBufferSubject.send(buffer)

        let normalizedPower = calculateAndPublishAudioLevel(channelData: channelData[0], frameCount: Int(frames))
        
        if isRecording {
            writeBufferToFile(buffer: buffer)
        }
    }

    // MARK: - Helper Methods

    private func installTapOnInputNode() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: audioBufferSize, format: inputFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer: buffer, time: time)
        }
    }

    private func startAudioEngine() {
        do {
            try audioEngine.start()
            isEngineRunning = true
            print("[AudioEngineManager] Audio engine started.")
        } catch {
            print("[AudioEngineManager] Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    private func cleanupAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isEngineRunning = false
        print("[AudioEngineManager] Audio engine stopped.")
    }

    private func createAudioFile() {
        let audioFilename = AudioFileManager.shared.getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        let inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        do {
            audioFile = try AVAudioFile(forWriting: audioFilename, settings: inputFormat.settings)
            isRecording = true
            print("[AudioEngineManager] Started recording to file: \(audioFilename)")
        } catch {
            print("[AudioEngineManager] Failed to create audio file for recording: \(error.localizedDescription)")
        }
    }

    private func finalizeRecording() {
        isRecording = false
        audioFile = nil
        print("[AudioEngineManager] Stopped recording.")
    }

    private func sendAudioDataToWebSocket(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frames = buffer.frameLength

        let data = Data(bytes: channelData[0], count: Int(frames) * MemoryLayout<Float>.size)
        webSocketManager?.sendAudioData(data)
    }

    private func writeBufferToFile(buffer: AVAudioPCMBuffer) {
        guard let audioFile = audioFile else { return }
        do {
            try audioFile.write(from: buffer)
        } catch {
            print("[AudioEngineManager] Failed to write buffer to file: \(error.localizedDescription)")
        }
    }

    private func calculateAndPublishAudioLevel(channelData: UnsafeMutablePointer<Float>, frameCount: Int) -> Float {
        let rms = calculateRMS(channelData: channelData, frameCount: frameCount)
        let avgPower = 20 * log10(rms)
        let normalizedPower = rms > 0 ? avgPower : -100.0 // Arbitrary low value

        DispatchQueue.main.async { [weak self] in
            self?.audioLevelSubject.send(normalizedPower)
        }
        
        return normalizedPower
    }

    
    /// Calculates the Root Mean Square (RMS) of the audio signal.
    /// - Parameters:
    ///   - channelData: Pointer to the audio samples.
    ///   - frameCount: Number of frames in the buffer.
    /// - Returns: The RMS value.
    private func calculateRMS(channelData: UnsafeMutablePointer<Float>, frameCount: Int) -> Float {
        // Step 1: Extract the relevant samples
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))
        
        // Step 2: Calculate the sum of squares
        let sumOfSquares = samples.reduce(0) { $0 + ($1 * $1) }
        
        // Step 3: Calculate the mean of the squares
        let meanSquare = sumOfSquares / Float(frameCount)
        
        // Step 4: Calculate the root mean square (RMS)
        let rms = sqrt(meanSquare)
        
        return rms
    }
}
