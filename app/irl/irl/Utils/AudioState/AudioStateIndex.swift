//
//  AudioState.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine
import Speech
import UIKit // Import UIKit to use UIDevice

// Singleton class responsible for managing the app's audio state, including recording, playback, and speech recognition.
// This class persists data (e.g., recordings) between sessions and ensures that the audio state is shared across different views.
class AudioState: NSObject, AudioStateProtocol, AVAudioPlayerDelegate {

    // Singleton instance to ensure one central state for audio management.
    static let shared = AudioState()

    // MARK: - Published Properties

    // Published properties allow SwiftUI views or other observers to reactively update when these values change.
    @Published var isRecording = false // Tracks if recording is in progress.
    @Published var isPlaying = false // Tracks if playback is in progress.
    @Published var recordingTime: TimeInterval = 0 // The time length of the current recording.
    @Published var recordingProgress: Double = 0 // Progress of the recording session.
    @Published var currentRecording: AudioRecording? // The recording currently being played or recorded.
    @Published var isPlaybackAvailable = false // Indicates if playback can be started for the current recording.
    @Published var errorMessage: String? // Holds error messages related to recording, playback, or speech recognition.
    @Published var localRecordings: [AudioRecording] = [] // List of recordings fetched from local storage.

    // Persistent storage for recording-related settings using @AppStorage, allowing the values to be stored and retrieved across app launches.
    @AppStorage("isRecordingEnabled") private(set) var isRecordingEnabled = false
    @AppStorage("isBackgroundRecordingEnabled") var isBackgroundRecordingEnabled = true // Default to true to enable background recording by default

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

    // MARK: - Initializer

    // Private initializer to enforce singleton pattern.
    private override init() {
        super.init()
        setupAudioSession(caller: "AudioState.init") // Setup called once during initialization.
        updateLocalRecordings() // Loads any existing recordings from disk.
        setupNotifications() // Setup app lifecycle notifications.

        // Automatically start recording if background recording is enabled
        if isBackgroundRecordingEnabled {
            startRecording()
        }
    }

    // MARK: - Notification Setup

    // Registers for system notifications related to the app's lifecycle.
    private func setupNotifications() {
        // Listen for when the app is about to go into the background (resign active).
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppBackgrounding), name: UIApplication.willResignActiveNotification, object: nil)
        
        // Listen for when the app is about to terminate.
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppTermination), name: UIApplication.willTerminateNotification, object: nil)
    }

    // Handles the app going into the background. If background recording is allowed, continue recording; otherwise, stop.
    @objc private func handleAppBackgrounding() {
        // If background recording is allowed, ensure the audio session is set up correctly.
        if isBackgroundRecordingEnabled {
            setupAudioSession()
        } else {
            // Otherwise, stop recording when the app is backgrounded.
            stopRecording()
        }
    }

    // Handles the app termination. Ensures that recording stops to prevent data loss or resource leaks.
    @objc private func handleAppTermination() {
        // If recording is active when the app is terminating, stop the recording process.
        if isRecording {
            stopRecording()
        }
    }

    // MARK: - WebSocket Setup

    // Assigns the WebSocket manager, enabling live audio streaming functionality.
    func setupWebSocket(manager: WebSocketManagerProtocol) {
        self.webSocketManager = manager
    }

    // MARK: - Audio Session Setup

    /// Configures the AVAudioSession to allow both playback and recording.
    /// - Parameter caller: A string indicating who called this method, for logging purposes.
    private func setupAudioSession(caller: String = #function) {
        // Log device information
        let device = UIDevice.current
        let deviceInfo = "Device: \(device.model), OS: \(device.systemName) \(device.systemVersion)"
        print("[DeviceInfo] Called by \(caller) - \(deviceInfo)")

        recordingSession = AVAudioSession.sharedInstance()

        // Check current session configuration
        let currentCategory = recordingSession?.category ?? .ambient
        let currentMode = recordingSession?.mode ?? .default
        let currentOptions = recordingSession?.categoryOptions ?? []

        if currentCategory == .playAndRecord &&
            currentMode == .default &&
            currentOptions.contains(.defaultToSpeaker) &&
            currentOptions.contains(.allowBluetooth) {
            print("[setupAudioSession] Called by \(caller) - Audio session already configured.")
            return
        }

        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(true)
            print("[setupAudioSession] Called by \(caller) - Audio session successfully set up")
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
                print("[setupAudioSession] Called by \(caller) - Setup failed: \(error.localizedDescription)")
            }
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
        if isRecording {
            stopRecording()
        }

        // Remove redundant call to setupAudioSession()
        // setupAudioSession(caller: "AudioState.startRecording")

        if webSocketManager != nil {
            startLiveStreaming()
        } else {
            startFileRecording()
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

        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            self?.stopRecordingTimer() // Stop the timer tracking the recording length.
            self?.updateCurrentRecording() // Save the recorded file and update the list of recordings.
            self?.updateLocalRecordings()
            self?.isPlaybackAvailable = true // After recording is stopped, playback becomes available.
        }
    }

    // MARK: - Live Streaming

    // Starts live audio streaming using AVAudioEngine.
    private func startLiveStreaming() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to create audio engine"
            }
            return
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Tapping into the audio stream and processing the microphone buffer for live streaming.
        inputNode.installTap(onBus: 0, bufferSize: audioBufferSize, format: inputFormat) { [weak self] (buffer, time) in
            self?.processMicrophoneBuffer(buffer: buffer, time: time)
        }

        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                try audioEngine.start() // Starts the audio engine to begin capturing audio data.
                DispatchQueue.main.async {
                    self?.isRecording = true
                    self?.recordingTime = 0
                    self?.recordingProgress = 0
                    self?.startRecordingTimer() // Starts a timer to track the duration of the recording.
                    self?.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
                }
            }
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
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Attempts to start the recording with the specified settings.
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self // Set the delegate to respond to recording events
            audioRecorder?.record()

            DispatchQueue.main.async { [weak self] in
                self?.isRecording = true
                self?.recordingTime = 0
                self?.recordingProgress = 0
                self?.startRecordingTimer() // Starts a timer to track recording duration.
                self?.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Could not start recording: \(error.localizedDescription)"
            }
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
        DispatchQueue.main.async { [weak self] in
            self?.recordingTimer?.invalidate()
            self?.recordingTimer = nil
        }
    }

    // Updates the audio levels by querying the current recording's meter data.
    private func updateAudioLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.updateMeters() // Updates the metering information for the audio input.
        let averagePower = recorder.averagePower(forChannel: 0)
        DispatchQueue.main.async { [weak self] in
            self?.audioLevelSubject.send(averagePower) // Publishes on the main thread.
        }
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
            determineSpeechLikelihood(for: recording.url) { [weak self] isSpeechLikely in
                DispatchQueue.main.async {
                    self?.currentRecording?.isSpeechLikely = isSpeechLikely
                    self?.updateLocalRecordings() // Updates local recordings with speech likelihood info.
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

        DispatchQueue.main.async { [weak self] in
            self?.localRecordings = updatedRecordings // Updates the local recordings array to reflect changes.
        }
    }

    // Fetches the list of recordings, useful for reloading the list in the UI.
    func fetchRecordings() {
        updateLocalRecordings()
    }

    // Deletes a recording file from local storage and updates the list of recordings.
    func deleteRecording(_ recording: AudioRecording) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                try AudioFileManager.shared.deleteRecording(recording) // Attempts to delete the recording file.
                DispatchQueue.main.async {
                    self?.updateLocalRecordings()

                    // If the deleted recording was the current one, reset playback availability.
                    if self?.currentRecording?.url == recording.url {
                        self?.currentRecording = nil
                        self?.isPlaybackAvailable = false
                    }

                    self?.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Error deleting recording: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Speech Recognition

    // Determines if the audio file contains speech by running it through the speech recognizer.
    private func determineSpeechLikelihood(for url: URL, completion: @escaping (Bool) -> Void) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        speechRecognizer?.recognitionTask(with: request) { result, error in
            if let _ = error {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            guard let result = result else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            // Analyzes the speech transcription result and confidence to determine if speech is present.
            let isSpeechLikely = result.bestTranscription.formattedString.split(separator: " ").count > 1 &&
                                (result.bestTranscription.segments.first?.confidence ?? 0 > 0.5)
            DispatchQueue.main.async {
                completion(isSpeechLikely)
            }
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
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "No recording available to play"
            }
            return
        }

        // Attempts to play the recording using AVAudioPlayer.
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.url)
            audioPlayer?.delegate = self // Set the delegate to respond to playback events.
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            DispatchQueue.main.async { [weak self] in
                self?.isPlaying = true
                self?.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Error playing audio: \(error.localizedDescription)"
            }
        }
    }

    // Pauses playback of the current recording.
    private func pausePlayback() {
        audioPlayer?.pause()
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
        }
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

// MARK: - AVAudioRecorderDelegate

extension AudioState: AVAudioRecorderDelegate {
    // Called when recording finishes, either successfully or with an error.
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Recording failed to finish successfully."
                self?.isRecording = false
            }
        }
    }

    // Called when recording encounters an encoding error.
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Recording encoding error: \(error.localizedDescription)"
                self?.isRecording = false
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioState {
    // Called when playback finishes, either successfully or with an error.
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false // Resets the isPlaying flag when playback is finished.
            if !flag {
                self?.errorMessage = "Playback finished with an error"
            }
        }
    }

    // Called when playback encounters an error.
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Playback decode error: \(error.localizedDescription)"
                self?.isPlaying = false
            }
        }
    }
}

//
//  AudioFileManager.swift
//  irl
//
//  Created by Elijah Arbee on 9/7/24.
//

import Foundation
import AVFoundation

class AudioFileManager {
    static let shared = AudioFileManager()

    private init() {}

    // Returns the URL for the app's document directory
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Updates the list of local audio recordings
    func updateLocalRecordings() -> [AudioRecording] {
        do {
            let documentsURL = getDocumentsDirectory()
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )

            return fileURLs.compactMap { url -> AudioRecording? in
                guard url.pathExtension == "m4a" else { return nil }
                
                let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
                let creationDate = attributes?[.creationDate] as? Date ?? Date()
                let fileSize = attributes?[.size] as? Int64 ?? 0
                let duration = getAudioDuration(for: url)

                return AudioRecording(
                    id: UUID(),
                    url: url,
                    creationDate: creationDate,
                    fileSize: fileSize,
                    isSpeechLikely: nil,  // Add logic elsewhere for determining speech likelihood
                    speechSegments: nil,  // Set when speech segments are detected
                    duration: duration,
                    location: nil,  // Add location if available in the future
                    transcriptionStatus: .pending,
                    ambientNoiseLevel: nil,
                    deviceInfo: nil,
                    processedAt: nil
                )
            }.sorted { $0.creationDate > $1.creationDate }
        } catch {
            print("Error fetching local recordings: \(error.localizedDescription)")
            return []
        }
    }

    // Deletes an audio recording
    func deleteRecording(_ recording: AudioRecording) throws {
        try FileManager.default.removeItem(at: recording.url)
    }

    // Returns the duration of the audio file
    private func getAudioDuration(for url: URL) -> TimeInterval? {
        let asset = AVAsset(url: url)
        let duration = asset.duration
        return duration.seconds.isNaN ? nil : duration.seconds
    }

    // Formats the file size for display
    func formattedFileSize(bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // Formats the duration for display in minutes and seconds
    func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

//
//  AudioUtils.swift
//  IRL
//
//  Created by Elijah Arbee on 10/11/24.
//

import Foundation

struct AudioUtils {
    /// Normalizes audio level from decibels to a range between 0 and 1
    static func normalizeAudioLevel(_ level: Float) -> Double {
        let minDb: Float = -80.0
        let maxDb: Float = 0.0
        let clampedLevel = max(min(level, maxDb), minDb)
        return Double((clampedLevel - minDb) / (maxDb - minDb))
    }
}

//
//  WebSocketManagerProtocol.swift
//  irl
//
//  Created by Elijah Arbee on 9/7/24.
//

import Foundation
import Combine

// MARK: - Protocols

protocol WebSocketManagerProtocol {
    var receivedDataPublisher: AnyPublisher<Data, Never> { get }
    func sendAudioData(_ data: Data)
}

protocol AudioStateProtocol: ObservableObject {
    var isRecording: Bool { get set }
    var isPlaying: Bool { get set }
    var recordingTime: TimeInterval { get set }
    var recordingProgress: Double { get set }
    var currentRecording: AudioRecording? { get set }
    var isPlaybackAvailable: Bool { get set }
    var errorMessage: String? { get set }
    var localRecordings: [AudioRecording] { get set }
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
    var formattedRecordingTime: String { get }

    func setupWebSocket(manager: WebSocketManagerProtocol)
    func toggleRecording()
    func stopRecording()
    func togglePlayback()
    func deleteRecording(_ recording: AudioRecording)
    func updateLocalRecordings()
    func formattedFileSize(bytes: Int64) -> String
}

// MARK: - WebSocketManager

class WebSocketManager: NSObject, WebSocketManagerProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private let receivedDataSubject = PassthroughSubject<Data, Never>()

    var receivedDataPublisher: AnyPublisher<Data, Never> {
        receivedDataSubject.eraseToAnyPublisher()
    }

    init(url: URL) {
        super.init()
        setupWebSocket(url: url)
    }

    private func setupWebSocket(url: URL) {
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()
    }

    func sendAudioData(_ data: Data) {
        webSocketTask?.send(.data(data)) { error in
            if let error = error {
                print("Error sending audio data: \(error.localizedDescription)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self?.receivedDataSubject.send(data)
                    }
                case .data(let data):
                    self?.receivedDataSubject.send(data)
                @unknown default:
                    print("Received unknown message type.")
                }
                self?.receiveMessage() // Continue listening for more messages
            case .failure(let error):
                print("Error receiving message: \(error.localizedDescription)")
                // Optionally, you might want to implement reconnection logic here
            }
        }
    }

    deinit {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
}

//
//  LocationManager.swift
//  irl
//
//  Created by Elijah Arbee on 10/14/24.
//

import Foundation
import CoreLocation
import Combine

// MARK: - LocationData Struct
/// Stores location data with additional metadata
struct LocationData: Codable {
    let uuid: String
    let latitude: Double?
    let longitude: Double?
    let accuracy: Double?
    let timestamp: Date
    let altitude: Double?
    let speed: Double?
    let course: Double?
    let isLocationAvailable: Bool
}

// MARK: - LocationManager Class
/// Manages user location tracking with metadata
class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    // Singleton instance
    static let shared = LocationManager()

    // Published properties for tracking location and error messages
    @Published var currentLocation: LocationData?
    @Published var locationErrorMessage: String?

    // Private properties
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var isMonitoringSignificantChanges = false
    private let locationSubject = PassthroughSubject<LocationData?, Never>()
    
    var locationPublisher: AnyPublisher<LocationData?, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    // Initializer
    private override init() {
        super.init()
        setupLocationManager()
    }

    // Configures CLLocationManager
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = true
        requestLocationAuthorization()
    }

    // Requests location authorization
    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    // CLLocationManagerDelegate method for handling authorization changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationErrorMessage = "Location access denied. Some features may be unavailable."
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }

    // CLLocationManagerDelegate method for handling location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        if let lastLoc = lastLocation, newLocation.distance(from: lastLoc) < locationManager.distanceFilter {
            locationManager.stopUpdatingLocation()
            startSignificantChangeMonitoring()
            return
        }

        let locationData = generateLocationData(for: newLocation)
        currentLocation = locationData
        locationSubject.send(locationData)
        lastLocation = newLocation
    }

    // Handles errors during location updates
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationErrorMessage = "Failed to get location: \(error.localizedDescription)"
        locationSubject.send(nil)
    }

    // Monitors significant location changes
    func startSignificantChangeMonitoring() {
        guard !isMonitoringSignificantChanges else { return }
        locationManager.startMonitoringSignificantLocationChanges()
        isMonitoringSignificantChanges = true
    }

    // Stops monitoring significant location changes
    func stopSignificantChangeMonitoring() {
        guard isMonitoringSignificantChanges else { return }
        locationManager.stopMonitoringSignificantLocationChanges()
        isMonitoringSignificantChanges = false
    }

    // Generates LocationData with metadata from a CLLocation
    private func generateLocationData(for location: CLLocation) -> LocationData {
        return LocationData(
            uuid: UUID().uuidString,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy,
            timestamp: location.timestamp,
            altitude: location.altitude,
            speed: location.speed,
            course: location.course,
            isLocationAvailable: true
        )
    }
}

//
//  SpeechRecognitionManager.swift
//  irl
//
//  Created by Elijah Arbee on 9/6/24.
//
import SwiftUI
import Speech
import Combine
import AVFoundation

// MARK: - Constants
private enum SpeechRecognitionConstants {
    static let locale = Locale(identifier: "en-US")
    static let bufferSize: AVAudioFrameCount = 1024
    static let backgroundNoiseCollectionDuration: TimeInterval = 10.0
    static let emaAlpha: Double = 0.1
    static let noiseChangeThreshold: Double = 0.05
    static let calibrationCooldown: TimeInterval = 60.0
}

// MARK: - SpeechRecognitionManager
class SpeechRecognitionManager: ObservableObject {
    static let shared = SpeechRecognitionManager()

    
    // MARK: - Published Properties
    @Published var transcribedText = "Transcribed text will appear here."
    @Published var transcriptionSegments: [String] = [] // This will hold recent segments in a streaming-like fashion
    @Published var currentAudioLevel: Double = 0.0
    @Published var averageBackgroundNoise: Double = 0.0
    @Published var isBackgroundNoiseReady: Bool = false
    @Published var isSpeechDetected: Bool = false // New flag for detecting if speech is detected
    @Published var speechMetadata: [String: Any] = [:] // Dictionary to store additional metadata about speech
    
    // MARK: - Persistent AppStorage Properties
    @AppStorage("isBackgroundNoiseCalibrated") private var isBackgroundNoiseCalibrated: Bool = false
    @AppStorage("averageBackgroundNoisePersisted") private var averageBackgroundNoisePersisted: Double = 0.0
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: SpeechRecognitionConstants.locale)!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var backgroundNoiseLevels: [Double] = []
    private var isCollectingBackgroundNoise = false
    private var backgroundNoiseTimer: Timer?
    private var lastTranscription: String = ""
    private var lastCalibrationTime: Date = .distantPast
    var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Streamed Properties
    private let maxSegmentCount = 10 // Limit how many segments to hold in memory at once for better memory usage
    
    // MARK: - Speech Authorization Request
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                self?.handleAuthorizationStatus(authStatus)
            }
        }
    }
    
    private func handleAuthorizationStatus(_ authStatus: SFSpeechRecognizerAuthorizationStatus) {
        switch authStatus {
        case .authorized:
            break
        case .denied, .restricted, .notDetermined:
            transcribedText = "Speech recognition not authorized."
        @unknown default:
            transcribedText = "Unknown authorization status."
        }
    }
    
    // MARK: - Recording Control
    func startRecording() {
        guard !audioEngine.isRunning else { return }
        resetRecognitionTask()
        setupAudioSession()
        initializeRecognitionRequest()
        startAudioEngine()
        subscribeToAudioLevelUpdates()
    }
    
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    // MARK: - Recognition Task Reset
    private func resetRecognitionTask() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            transcribedText = "Failed to set up audio session: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Recognition Request Initialization
    private func initializeRecognitionRequest() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            self?.handleStreamingResult(result, error)
        }
    }

    // MARK: - Streaming Transcription Handling
    private func handleStreamingResult(_ result: SFSpeechRecognitionResult?, _ error: Error?) {
        guard let result = result else { return }
        DispatchQueue.main.async {
            // Streaming transcription: handle partial results in real-time
            self.transcribedText = result.bestTranscription.formattedString
            self.updateTranscriptionSegments(from: result.bestTranscription)
            self.isSpeechDetected = !result.bestTranscription.formattedString.isEmpty // Update the speech detection flag
            self.speechMetadata = [
                "isFinal": result.isFinal,
                "confidence": result.bestTranscription.segments.last?.confidence ?? 0.0,
                // "duration": result.bestTranscription.duration,
                "formattedStringLength": result.bestTranscription.formattedString.count
            ]
        }
        if error != nil || result.isFinal {
            stopRecording()
        }
    }

    // MARK: - Audio Engine Control
    private func startAudioEngine() {
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: SpeechRecognitionConstants.bufferSize, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            DispatchQueue.main.async {
                self.transcribedText = "Listening..."
            }
        } catch {
            transcribedText = "Audio Engine couldn't start: \(error.localizedDescription)"
        }
    }

    // MARK: - Transcription Segments Streaming Update
    private func updateTranscriptionSegments(from transcription: SFTranscription) {
        let newSegments = transcription.segments.dropFirst(transcriptionSegments.count)
        newSegments.forEach { segment in
            let start = transcription.formattedString.index(transcription.formattedString.startIndex, offsetBy: segment.substringRange.location)
            let end = transcription.formattedString.index(start, offsetBy: segment.substringRange.length)
            let substring = String(transcription.formattedString[start..<end])
            
            // Append to segments but ensure we are not holding too many in memory
            transcriptionSegments.append(substring)
            if transcriptionSegments.count > maxSegmentCount {
                transcriptionSegments.removeFirst() // Remove old segments to free up memory
            }
        }
    }
    
    // MARK: - Audio Level Subscriptions
    private func subscribeToAudioLevelUpdates() {
        AudioState.shared.audioLevelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.handleAudioLevel(level)
            }
            .store(in: &cancellables)
    }

    // MARK: - Background Noise Handling
    private func handleAudioLevel(_ level: Float) {
        let normalizedLevel = AudioUtils.normalizeAudioLevel(level)
        
        if isUserSpeaking() {
            resetBackgroundNoiseCollection()
        } else {
            backgroundNoiseLevels.append(normalizedLevel)
            if !isBackgroundNoiseCalibrated {
                startBackgroundNoiseCollection()
            } else {
                updateNoiseIfCalibrated(normalizedLevel)
            }
        }
        
        adjustCurrentAudioLevelIfReady(normalizedLevel)
    }
    
    private func isUserSpeaking() -> Bool {
        if transcribedText != lastTranscription && !transcribedText.isEmpty {
            lastTranscription = transcribedText
            return true
        }
        return false
    }

    private func startBackgroundNoiseCollection() {
        guard !isCollectingBackgroundNoise else { return }
        isCollectingBackgroundNoise = true
        backgroundNoiseLevels.removeAll()
        
        backgroundNoiseTimer = Timer.scheduledTimer(withTimeInterval: SpeechRecognitionConstants.backgroundNoiseCollectionDuration, repeats: false) { [weak self] _ in
            self?.computeAverageBackgroundNoise()
            self?.isCollectingBackgroundNoise = false
        }
    }

    private func resetBackgroundNoiseCollection() {
        backgroundNoiseTimer?.invalidate()
        backgroundNoiseTimer = nil
        isCollectingBackgroundNoise = false
        backgroundNoiseLevels.removeAll()
        
        if Date().timeIntervalSince(lastCalibrationTime) > SpeechRecognitionConstants.calibrationCooldown {
            averageBackgroundNoise = 0.0
            isBackgroundNoiseCalibrated = false
            isBackgroundNoiseReady = false
        }
    }
    
    private func computeAverageBackgroundNoise() {
        guard !backgroundNoiseLevels.isEmpty else { return }
        let average = backgroundNoiseLevels.reduce(0, +) / Double(backgroundNoiseLevels.count)
        DispatchQueue.main.async {
            self.updateBackgroundNoise(average)
        }
    }

    private func updateBackgroundNoise(_ average: Double) {
        averageBackgroundNoise = average
        averageBackgroundNoisePersisted = average
        isBackgroundNoiseCalibrated = true
        isBackgroundNoiseReady = true
        lastCalibrationTime = Date()
        print("Average Background Noise Updated: \(averageBackgroundNoisePersisted)")
    }

    private func updateNoiseIfCalibrated(_ normalizedLevel: Double) {
        if Date().timeIntervalSince(lastCalibrationTime) > SpeechRecognitionConstants.calibrationCooldown {
            let newEma = (SpeechRecognitionConstants.emaAlpha * averageBackgroundNoisePersisted) + ((1 - SpeechRecognitionConstants.emaAlpha) * normalizedLevel)
            let change = abs(newEma - averageBackgroundNoisePersisted)
            if change > SpeechRecognitionConstants.noiseChangeThreshold {
                updateBackgroundNoise(newEma)
            }
        }
    }

    // Adjust the currentAudioLevel calculation
    private func adjustCurrentAudioLevelIfReady(_ normalizedLevel: Double) {
        let alpha: Double = 0.3 // Tweak this value to control noise influence
        if isBackgroundNoiseReady {
            let adjustedLevel = max(normalizedLevel - alpha * averageBackgroundNoisePersisted, 0.0)
            currentAudioLevel = adjustedLevel / (1.0 - alpha * averageBackgroundNoisePersisted)
        } else {
            currentAudioLevel = normalizedLevel
        }
    }
}
