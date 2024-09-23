//
//  AudioStateIndex.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//

import Foundation
import AVFoundation
import Combine
import Speech

// Singleton class responsible for managing the app's audio state, including recording, playback, and speech recognition.
// This class persists data (e.g., recordings) between sessions and ensures that the audio state is shared across different views.
class AudioState: NSObject, AudioStateProtocol {
    static let shared = AudioState() // Singleton instance to ensure one central state for audio management.

    // Published properties allow SwiftUI views or other observers to reactively update when these values change.
    @Published var isRecording = false // Tracks if recording is in progress.
    @Published var isPlaying = false // Tracks if playback is in progress.
    @Published var recordingTime: TimeInterval = 0 // The time length of the current recording.
    @Published var recordingProgress: Double = 0 // Progress of the recording session.
    @Published var currentRecording: AudioRecording? // The recording currently being played or recorded.
    @Published var isPlaybackAvailable = false // Indicates if playback can be started for the current recording.
    @Published var errorMessage: String? // Holds error messages related to recording, playback, or speech recognition.
    @Published var localRecordings: [AudioRecording] = [] // List of recordings fetched from local storage.

    // AVFoundation components for handling audio recording and playback.
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    private var recordingTimer: Timer? // Timer for tracking recording duration.
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) // For speech recognition tasks.

    // Combine subject to track audio levels in real-time.
    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher() // Allows external subscribers to receive audio level updates.
    }

    private var audioEngine: AVAudioEngine? // For live audio streaming.
    private var webSocketManager: WebSocketManagerProtocol? // WebSocket manager for live audio streaming.
    private let audioBufferSize: AVAudioFrameCount = 1024 // Size of the audio buffer for live streaming.

    private var cancellables: Set<AnyCancellable> = [] // Stores Combine subscriptions.

    // Initializer sets up the audio session and loads any existing recordings from disk.
    override init() {
        super.init()
        setupAudioSession() // Prepares the app for recording and playback.
        updateLocalRecordings() // Fetches stored recordings to ensure persistence between sessions.
    }

    // Assigns the WebSocket manager, enabling live audio streaming functionality.
    func setupWebSocket(manager: WebSocketManagerProtocol) {
        self.webSocketManager = manager
    }

    // MARK: - Audio Session Setup

    // Configures the AVAudioSession to allow both playback and recording.
    private func setupAudioSession() {
        do {
            recordingSession = AVAudioSession.sharedInstance()
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
        }
    }

    // MARK: - Recording Controls

    // Toggles between starting and stopping a recording session.
    func toggleRecording() {
        if isRecording {
            stopRecording() // If already recording, stop the current session.
        } else {
            startRecording() // Otherwise, begin a new recording session.
        }
    }

    // Starts either live streaming or file-based recording depending on the presence of a WebSocketManager.
    func startRecording() {
        if webSocketManager != nil {
            startLiveStreaming() // If WebSocketManager is available, start live streaming.
        } else {
            startFileRecording() // Otherwise, start recording to a file.
        }
    }

    // Stops the current recording, whether live-streaming or file-based, and updates the UI and local recordings.
    func stopRecording() {
        if let audioEngine = audioEngine {
            audioEngine.stop() // Stop the audio engine if live streaming.
            audioEngine.inputNode.removeTap(onBus: 0)
            self.audioEngine = nil
        } else {
            audioRecorder?.stop() // Otherwise, stop the file-based recording.
        }

        isRecording = false
        stopRecordingTimer() // Stop the timer tracking the recording length.
        updateCurrentRecording() // Save the recorded file and update the list of recordings.
        updateLocalRecordings()
        isPlaybackAvailable = true // After recording is stopped, playback becomes available.
    }

    // MARK: - Live Streaming

    // Starts live audio streaming using AVAudioEngine.
    private func startLiveStreaming() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            errorMessage = "Failed to create audio engine"
            return
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Tapping into the audio stream and processing the microphone buffer for live streaming.
        inputNode.installTap(onBus: 0, bufferSize: audioBufferSize, format: inputFormat) { [weak self] (buffer, time) in
            self?.processMicrophoneBuffer(buffer: buffer, time: time)
        }

        do {
            try audioEngine.start() // Starts the audio engine to begin capturing audio data.
            isRecording = true
            recordingTime = 0
            recordingProgress = 0
            startRecordingTimer() // Starts a timer to track the duration of the recording.
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }

    // Processes the captured audio buffer and sends it via WebSocket for live streaming.
    private func processMicrophoneBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let channelData = buffer.floatChannelData else { return }
        let frames = buffer.frameLength

        var data = Data(capacity: Int(frames) * MemoryLayout<Float>.size)
        for i in 0..<Int(frames) {
            var sample = channelData[0][i]
            data.append(Data(bytes: &sample, count: MemoryLayout<Float>.size))
        }

        webSocketManager?.sendAudioData(data) // Sends the processed audio data to the WebSocket server.
    }

    // MARK: - File Recording

    // Starts a new file-based recording, saving the audio data locally.
    private func startFileRecording() {
        // Generates a unique file path for the recording based on the current timestamp.
        let audioFilename = AudioFileManager.shared.getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")

        // Audio settings for the recording session (AAC format, high-quality audio).
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Attempts to start the recording with the specified settings.
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            isRecording = true
            recordingTime = 0
            recordingProgress = 0
            startRecordingTimer() // Starts a timer to track recording duration.
            errorMessage = nil
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }

    // MARK: - Recording Timer
    
    // Starts a timer that increments the recording duration every 0.1 seconds and updates the audio levels.
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.recordingTime += 0.1
                self.updateAudioLevels() // Updates the current audio levels during the recording.
            }
        }
    }

    // Stops the timer that tracks the recording duration.
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // Updates the audio levels by querying the current recording's meter data.
    private func updateAudioLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters() // Updates the metering information for the audio input.
        let averagePower = recorder.averagePower(forChannel: 0)
        audioLevelSubject.send(averagePower) // Sends the current audio level via the Combine publisher.
    }

    // MARK: - File Management

    // Saves the current recording and updates the list of local recordings.
    private func updateCurrentRecording() {
        guard let url = audioRecorder?.url else { return }
        let fileManager = AudioFileManager.shared
        let recordings = fileManager.updateLocalRecordings() // Fetches the latest recordings from local storage.
        currentRecording = recordings.first { $0.url == url } // Sets the current recording based on the URL.

        // Performs speech likelihood analysis on the newly saved recording.
        if let recording = currentRecording {
            determineSpeechLikelihood(for: recording.url) { isSpeechLikely in
                DispatchQueue.main.async {
                    self.currentRecording?.isSpeechLikely = isSpeechLikely
                    self.updateLocalRecordings() // Updates local recordings with speech likelihood info.
                }
            }
        }
    }

    // Updates the list of local recordings by querying the file system for saved recordings.
    func updateLocalRecordings() {
        let updatedRecordings = AudioFileManager.shared.updateLocalRecordings()
        
        // For each recording, if speech likelihood has not been determined, initiate speech analysis.
        for recording in updatedRecordings {
            if recording.isSpeechLikely == nil {
                determineSpeechLikelihood(for: recording.url) { [weak self] isSpeechLikely in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        if let index = self.localRecordings.firstIndex(where: { $0.url == recording.url }) {
                            self.localRecordings[index].isSpeechLikely = isSpeechLikely // Updates likelihood result.
                        }
                    }
                }
            }
        }
        
        self.localRecordings = updatedRecordings // Updates the local recordings array to reflect changes.
    }
    
    // Fetches the list of recordings, useful for reloading the list in the UI.
    func fetchRecordings() {
        updateLocalRecordings()
    }

    // Deletes a recording file from local storage and updates the list of recordings.
    func deleteRecording(_ recording: AudioRecording) {
        do {
            try AudioFileManager.shared.deleteRecording(recording) // Attempts to delete the recording file.
            updateLocalRecordings()

            // If the deleted recording was the current one, reset playback availability.
            if currentRecording?.url == recording.url {
                currentRecording = nil
                isPlaybackAvailable = false
            }

            errorMessage = nil
        } catch {
            errorMessage = "Error deleting recording: \(error.localizedDescription)"
        }
    }

    // MARK: - Speech Recognition

    // Determines if the audio file contains speech by running it through the speech recognizer.
    private func determineSpeechLikelihood(for url: URL, completion: @escaping (Bool) -> Void) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        speechRecognizer?.recognitionTask(with: request) { result, error in
            guard let result = result else {
                completion(false)
                return
            }
            
            // Analyzes the speech transcription result and confidence to determine if speech is present.
            let isSpeechLikely = result.bestTranscription.formattedString.split(separator: " ").count > 1 && result.bestTranscription.segments.first?.confidence ?? 0 > 0.5
            completion(isSpeechLikely)
        }
    }

    // MARK: - Playback Controls

    // Toggles between starting and pausing playback.
    func togglePlayback() {
        if isPlaying {
            pausePlayback() // If currently playing, pause the playback.
        } else {
            startPlayback() // Otherwise, start playback.
        }
    }

    // Starts playback of the current recording.
    private func startPlayback() {
        guard let recording = currentRecording else {
            errorMessage = "No recording available to play"
            return
        }

        // Attempts to play the recording using AVAudioPlayer.
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.url)
            audioPlayer?.delegate = self // Set the delegate to respond to playback events.
            audioPlayer?.play()
            isPlaying = true
            errorMessage = nil
        } catch {
            errorMessage = "Error playing audio: \(error.localizedDescription)"
        }
    }

    // Pauses playback of the current recording.
    private func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
    }

    // MARK: - Formatting Helpers

    // Formats the recording duration for display purposes.
    var formattedRecordingTime: String {
        AudioFileManager.shared.formattedDuration(recordingTime)
    }

    // Formats the file size of a recording for display.
    func formattedFileSize(bytes: Int64) -> String {
        AudioFileManager.shared.formattedFileSize(bytes: bytes)
    }
}

// MARK: - AVAudioPlayerDelegate

// Conforms to AVAudioPlayerDelegate to handle events like the end of playback.
extension AudioState: AVAudioPlayerDelegate {
    // Called when playback finishes, either successfully or with an error.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false // Resets the isPlaying flag when playback is finished.
        if !flag {
            errorMessage = "Playback finished with an error"
        }
    }
}
