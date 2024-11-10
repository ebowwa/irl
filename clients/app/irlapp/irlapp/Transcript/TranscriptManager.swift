//
//  Created by Elijah Arbee on 11/2/24.
//

// the following works at transcription which is good, the issues is that it accumulates.. without showing clear breaks and therefore new sentences in dialogue.

// i want to take clear sentences, strings and to be able to segment the audio associated with the transcriptions (later on we will focus on saving these for other transformations)

// the view needs to allow small cards that can show additional context a generated (and maybe requested by user) by additional gemini instance
//

// at maybe 30 second intervals(if 30 seconds mybe no need for socket.., but maybe a socket is better for first testing thsi as highest chance of success without configurations) i want to send to the backend - i want the backends respond to override the local transcriptions with the backend transcriptions - this will likely be a websocket especially right now - i will want to display the results which will likely be json formatted
//      - audio will be saved as wav
// Segmented Transcription and Audio Mapping: Improve handling of individual sentences and audio snippets by pairing transcription entries with associated audio timestamps.


//  TranscriptionManager.swift
//
//  Created by Elijah Arbee on 11/2/24.
//
//  Updated by ChatGPT on 04/27/2024.
//

import AVFoundation
import Foundation
import NaturalLanguage
import Speech
import SwiftUI

// Ensure that TranscriptEntry is accessible
// If using modules, you might need to import the module containing TranscriptEntry

// MARK: - TranscriptionManager Class

/// Manages audio recording, speech recognition, and transcript handling.
class TranscriptionManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Continuous transcribed text.
    @Published var transcribedText: String = ""
    
    /// Current audio level for visualization.
    @Published var audioLevel: Double = 0.0
    
    /// Indicates if recording is active.
    @Published var isRecording: Bool = false
    
    /// Indicates if calibration is in progress.
    @Published var isCalibrating: Bool = true
    
    /// Stores error messages.
    @Published var errorMessage: String?
    
    /// List of transcript entries.
    @Published var transcriptEntries: [TranscriptEntry] = []
    
    // MARK: - Private Properties
    
    /// Manages audio input.
    private let audioEngine = AVAudioEngine()
    
    /// Speech recognizer instance.
    private let speechRecognizer: SFSpeechRecognizer?
    
    /// Recognition request.
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// Recognition task.
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Node for audio level monitoring.
    private var audioLevelNode: AVAudioMixerNode?
    
    /// Start time of recording.
    private var recordingStartTime: Date?
    
    /// Counter for sequence numbering.
    private var sequenceCounter: Int = 0
    
    /// Tracks the last finalized transcription.
    private var lastFinalTranscription: String = ""
    
    /// Natural Language Recognizer.
    private lazy var languageRecognizer: NLLanguageRecognizer = {
        let recognizer = NLLanguageRecognizer()
        return recognizer
    }()
    
    /// Natural Language Tagger.
    private lazy var tagger: NLTagger = {
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType, .lemma])
        return tagger
    }()
    
    // MARK: - Initializer
    
    /// Sets up the speech recognizer, audio session, audio level monitoring, and requests permissions.
    override init() {
        // 1. Initialize Speech Recognizer
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        super.init()
        
        // 2. Setup Audio Session
        setupAudioSession()
        
        // 3. Setup Audio Level Monitoring
        setupAudioLevelMonitoring()
        
        // 4. Request Permissions
        requestPermissions()
    }
    
    // MARK: - Audio Session Setup
    
    /// Configures the audio session for recording and playback.
    private func setupAudioSession() {
        do {
            // 5. Configure Audio Session Category and Mode
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try audioSession.setPreferredIOBufferDuration(0.005)
        } catch {
            // 6. Handle Audio Session Setup Errors
            DispatchQueue.main.async {
                self.errorMessage = "Failed to set up audio session: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Audio Level Monitoring
    
    /// Sets up a mixer node to monitor audio levels for visualization.
    private func setupAudioLevelMonitoring() {
        // 7. Initialize Mixer Node
        audioLevelNode = AVAudioMixerNode()
        guard let mixerNode = audioLevelNode else { return }
        
        // 8. Attach and Connect Mixer Node
        audioEngine.attach(mixerNode)
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        // 9. Install Tap to Monitor Audio Levels
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processTapBuffer(buffer)
        }
    }
    
    /// Processes audio buffer to determine the current audio level.
    private func processTapBuffer(_ buffer: AVAudioPCMBuffer) {
        // 10. Extract Channel Data
        guard let channelData = buffer.floatChannelData else { return }
        let channelCount = Int(buffer.format.channelCount)
        let length = Int(buffer.frameLength)
        
        // 11. Calculate Maximum Amplitude
        var maxAmplitude: Float = 0.0
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<length {
                maxAmplitude = max(maxAmplitude, abs(data[frame]))
            }
        }
        
        // 12. Convert Amplitude to Decibels and Normalize
        let db = 20 * log10(maxAmplitude)
        let normalizedValue = (db + 60) / 60
        
        // 13. Update Audio Level on Main Thread
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = Double(max(0, min(1, normalizedValue)))  // Normalize between 0 and 1
        }
    }
    
    // MARK: - Permissions Request
    
    /// Requests permissions for speech recognition and microphone access.
    private func requestPermissions() {
        // 14. Request Speech Recognition Authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.startCalibration()
                case .denied, .restricted, .notDetermined:
                    self?.errorMessage = "Speech recognition authorization denied"
                @unknown default:
                    self?.errorMessage = "Unknown authorization status"
                }
            }
        }
        
        // 15. Request Microphone Access using AVAudioApplication (iOS 17.0+)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.errorMessage = "Microphone access denied"
                    }
                }
            }
        } else {
            // 16. Fallback on Earlier Versions
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted {
                        self?.errorMessage = "Microphone access denied"
                    }
                }
            }
        }
    }
    
    // MARK: - Calibration
    
    /// Calibrates the microphone by measuring ambient audio levels.
    private func startCalibration() {
        // 17. Begin Calibration Process
        isCalibrating = true
        var samples: [Double] = []
        
        do {
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
        } catch {
            // 18. Handle Audio Engine Start Errors
            DispatchQueue.main.async {
                self.errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            }
            return
        }
        
        // 19. Timer to Collect Audio Level Samples for Calibration
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            samples.append(self.audioLevel)
            
            if samples.count >= 20 {  // Collect 2 seconds of samples
                timer.invalidate()
                self.isCalibrating = false
                self.startRecording()
            }
        }
    }
    
    // MARK: - Recording Control
    
    /// Initiates the speech recognition and starts recording audio.
    func startRecording() {
        guard let recognizer = speechRecognizer,
              recognizer.isAvailable
        else {
            DispatchQueue.main.async {
                self.errorMessage = "Speech recognition unavailable"
            }
            return
        }
        
        // 20. Reset Variables for a New Recording Session
        recordingStartTime = Date()
        transcriptEntries.removeAll()
        sequenceCounter = 0
        lastFinalTranscription = ""
        
        // 21. Initialize Recognition Request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // 22. Install Tap on Input Node to Capture Audio
        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // 23. Start Recognition Task
        recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                // 24. Update Live Transcription
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                
                if result.isFinal {
                    DispatchQueue.main.async {
                        let fullTranscription = result.bestTranscription.formattedString
                        let newText: String
                        
                        if fullTranscription.hasPrefix(self.lastFinalTranscription) {
                            newText = String(fullTranscription.dropFirst(self.lastFinalTranscription.count))
                        } else {
                            // 25. Handle Unexpected Transcription Changes
                            newText = fullTranscription
                        }
                        
                        self.lastFinalTranscription = fullTranscription
                        self.createTranscriptEntry(for: newText)
                        self.transcribedText = ""  // Clear live transcription
                    }
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                // 26. Restart Recording on Error or Final Result
                self.restartRecording()
            }
        }
        
        // 27. Start Audio Engine
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            // 28. Handle Audio Engine Start Errors
            DispatchQueue.main.async {
                self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Transcript Entry Creation
    
    /// Creates a new transcript entry for a finalized transcription.
    private func createTranscriptEntry(for text: String) {
        // 29. Ensure Text is Not Empty
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        sequenceCounter += 1
        
        // 30. Create TranscriptEntry Instance
        let entry = TranscriptEntry(
            text: text,
            timestamp: Date(),
            startTime: 0,  // To be updated with accurate timing
            endTime: 0,    // To be updated with accurate timing
            sequenceNumber: sequenceCounter
        )
        
        // 31. Append Entry to Transcript Entries
        DispatchQueue.main.async {
            self.transcriptEntries.append(entry)
            print("New transcript entry (#\(self.sequenceCounter)): \(text)")
        }
    }
    
    // MARK: - Recording Restart
    
    /// Stops and restarts the recording process, typically used after an error.
    private func restartRecording() {
        // 32. Stop Current Recording Session
        stopRecording()
        
        // 33. Restart Recording After a Short Delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startRecording()
        }
    }
    
    // MARK: - Stop Recording
    
    /// Stops the audio engine and recognition task.
    func stopRecording() {
        // 34. Remove Tap and Stop Audio Engine
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        // 35. End and Cancel Recognition Request and Task
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }
    
    // MARK: - Clear Transcription
    
    /// Clears all transcribed text and transcript entries.
    func clearTranscription() {
        DispatchQueue.main.async {
            self.transcribedText = ""
            self.transcriptEntries.removeAll()
            self.sequenceCounter = 0
            self.lastFinalTranscription = ""
        }
    }
    
    // MARK: - Deinitializer
    
    /// Cleans up by stopping recording and removing audio taps when the object is deallocated.
    deinit {
        // 36. Ensure Recording is Stopped and Taps are Removed
        stopRecording()
        audioLevelNode?.removeTap(onBus: 0)
    }
}
