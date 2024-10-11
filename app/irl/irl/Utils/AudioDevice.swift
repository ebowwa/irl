//
//  AudioDevice.swift
//  IRL
//
//  Created by Elijah Arbee on 10/10/24.
//
// Device.swift
import Foundation

protocol Device: AnyObject {
    var identifier: UUID { get }
    var name: String { get }
    var isConnected: Bool { get set }
    var isRecording: Bool { get set }

    func connect()
    func disconnect()
    func startRecording()
    func stopRecording()
}

import Foundation
import AVFoundation

class AudioDevice: Device {
    let identifier: UUID
    let name: String
    var isConnected: Bool = false
    var isRecording: Bool = false
    var isPlaying: Bool = false

    private var audioState: AudioState

    init(name: String, audioState: AudioState = .shared) {
        self.identifier = UUID()
        self.name = name
        self.audioState = audioState
    }

    func connect() {
        isConnected = true
        print("\(name) connected.")
    }

    func disconnect() {
        isConnected = false
        print("\(name) disconnected.")
    }

    func startRecording() {
        guard isConnected else { return }
        audioState.startRecording()
        isRecording = true
        print("Recording started on \(name).")
    }

    func stopRecording() {
        guard isConnected else { return }
        audioState.stopRecording()
        isRecording = false
        print("Recording stopped on \(name).")
    }
}
