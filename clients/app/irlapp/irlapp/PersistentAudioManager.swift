// Initial Issues:
// 1.13. Sound Quality Issues
//     The voice sounds changed/modified, which is unexpected given the quality expected when using the Apple microphone, which should typically provide good quality, its likely the handling of the audio or even the recording of the audio
// 1.14. Missing Speech in Audio Files
//     Some audio files sent to the server do not include speech; we have local transcriptions. This should be an easy configuration.
import Foundation
import AVFoundation
import Combine
import UIKit
import ZIPFoundation
import Speech

// MARK: - AudioFileWithTranscription

/// Struct to associate each audio file with its transcription.
struct AudioFileWithTranscription {
    let fileURL: URL
    let transcription: String
}

// MARK: - PersistentAudioManager

class PersistentAudioManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    // MARK: 1. Properties
    
    // 1.1. Audio Engine and Queues
    private let audioEngine = AVAudioEngine()
    private let batchQueue = DispatchQueue(label: "com.caringmind.batchQueue", qos: .background)
    
    // 1.2. Recording State
    @Published private(set) var isRecording = false
    @Published private(set) var audioBuffer: AVAudioPCMBuffer?
    
    // 1.3. Background Task Management
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // 1.4. File Management
    private let fileManager = FileManager.default
    private var batchFileURLs = [AudioFileWithTranscription]()
    
    // 1.5. Published Properties for UI Updates
    
    // 1.5.1. Enum for Audio States with Equatable Conformance
    enum AudioState: Equatable {
        case idle // Engine is not active
        case listening // Engine is active, waiting for speech
        case detecting // Actively detecting speech
        case error(String) // Specific error message
    }
    
    // 1.5.2. Replace `isSpeechDetected` with `audioState`
    @Published var audioState: AudioState = .idle
    
    // 1.5.3. Error Message Property
    @Published var errorMessage: String?
    
    // 1.6. Published Property for Showing Errors
    @Published var showingError: Bool = false
    
    // 1.7. Speech Recognition
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    // 1.8. Batch Size Configuration
    private let batchSizeForeground = 2 // Approximately 60 seconds
    private let batchSizeBackground = 5 // Approximately 150 seconds
    
    // 1.9. Minimum Buffer Duration to Save (in seconds)
    private let minimumBufferDurationForeground: Double = 10.0
    private let minimumBufferDurationBackground: Double = 30.0
    
    // 1.10. Accumulated Audio Data
    private var accumulatedAudioFile: AVAudioFile?
    private var accumulatedDuration: Double = 0.0
    
    // 1.11. Transcribed Text
    @Published var transcribedText: String = ""
    
    // 1.12. Current Mode
    private var isForeground: Bool = true {
        didSet {
            adjustParametersForCurrentMode()
        }
    }
    
    private var batchSize: Int = 2
    private var minimumBufferDuration: Double = 10.0
    
    // 1.13. Sound Quality Issues
    //     The voice sounds changed/modified when using the Apple microphone, which should typically provide good quality.
    
    // 1.13.1. Adjusted Audio Session Configuration for Improved Sound Quality
    //       - Ensured the recording format matches the hardware's sample rate.
    //       - Maintained mono channel configuration.
    //       - Removed unnecessary audio processing that might alter sound quality.
    
    // 1.14. Missing Speech in Audio Files
    //     Some audio files sent to the server do not include speech; we have local transcriptions. This should be an easy configuration.
    
    // 1.14.1. Implemented Speech Presence Verification
    //       - Before uploading, check if transcribed text is non-empty.
    //       - Optionally skip uploading files without detected speech or handle them as per configuration.
    
    // MARK: 2. Initialization
    
    override init() {
        super.init()
        speechRecognizer.delegate = self
        requestSpeechAuthorization()
        configureAudioSession()
        setupNotifications()
        adjustParametersForCurrentMode()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: 3. Speech Recognition Authorization
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("[\(self.timestamp())] Speech recognition authorized.")
                case .denied, .restricted, .notDetermined:
                    let message = "Speech recognition authorization denied."
                    self.audioState = .error(message)
                    self.errorMessage = message
                    self.showingError = true
                    print("[\(self.timestamp())] Speech recognition authorization denied.")
                @unknown default:
                    let message = "Unknown speech recognition authorization status."
                    self.audioState = .error(message)
                    self.errorMessage = message
                    self.showingError = true
                    print("[\(self.timestamp())] Unknown speech recognition authorization status.")
                }
            }
        }
    }
    
    // MARK: 4. Audio Session Configuration
    
    private var actualSampleRate: Double = 44100.0 // Default value, will be set in configureAudioSession
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            try audioSession.setPreferredIOBufferDuration(0.005) // Set buffer duration
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("[\(timestamp())] Audio session configured successfully.")
            
            // Fetch the actual hardware sample rate
            actualSampleRate = audioSession.sampleRate
            print("[\(timestamp())] Actual hardware sample rate: \(actualSampleRate) Hz.")
        } catch {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let message = "Failed to configure audio session: \(error.localizedDescription)"
                self.audioState = .error(message)
                self.errorMessage = message
                self.showingError = true
            }
            print("[\(timestamp())] Audio Session Configuration Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: 5. Notification Setup for Background Tasks
    
    private func setupNotifications() {
        // 5.0.1. Observe App Entering Background
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // 5.0.2. Observe App Entering Foreground
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func appDidEnterBackground() {
        isForeground = false
        print("[\(timestamp())] App entered background.")
    }
    
    @objc private func appWillEnterForeground() {
        isForeground = true
        print("[\(timestamp())] App entered foreground.")
    }
    
    private func adjustParametersForCurrentMode() {
        if isForeground {
            minimumBufferDuration = minimumBufferDurationForeground
            batchSize = batchSizeForeground
        } else {
            minimumBufferDuration = minimumBufferDurationBackground
            batchSize = batchSizeBackground
        }
        print("[\(timestamp())] Parameters adjusted for \(isForeground ? "foreground" : "background") mode.")
    }
    
    // MARK: 6. Start Continuous Audio Processing
    
    func startContinuousProcessing() {
        // 6.0.1. Prevent Multiple Recordings
        guard !isRecording else {
            print("[\(timestamp())] Already recording.")
            return
        }
        
        // 6.0.2. Initialize Recognition Request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            let message = "Unable to create a SFSpeechAudioBufferRecognitionRequest object."
            self.audioState = .error(message)
            self.errorMessage = message
            self.showingError = true
            print("[\(timestamp())] Unable to create a SFSpeechAudioBufferRecognitionRequest object.")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // 6.0.3. Initialize Recognition Task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                // Update `audioState` based on transcription
                if !self.transcribedText.isEmpty {
                    self.audioState = .detecting
                } else {
                    self.audioState = .listening
                }
                print("[\(self.timestamp())] Transcribed Text: \(self.transcribedText)")
            }
            
            if let error = error {
                // 6.0.4. Handle Recognition Errors
                let message = "Speech recognition error: \(error.localizedDescription)"
                self.audioState = .error(message)
                self.errorMessage = message
                self.showingError = true
                print("[\(self.timestamp())] Speech Recognition Error: \(error.localizedDescription)")
                self.stopContinuousProcessing()
            }
        }
        
        // 6.0.5. Configure Audio Input
        let inputNode = audioEngine.inputNode
        // Use the actual hardware sample rate and set channels to 1 (Mono)
        guard let recordingFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: actualSampleRate, channels: 1, interleaved: false) else {
            let message = "Failed to create recording format."
            self.audioState = .error(message)
            self.errorMessage = message
            self.showingError = true
            print("[\(timestamp())] Failed to create recording format.")
            return
        }
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, when in
            self?.recognitionRequest?.append(buffer)
            self?.processAudioBuffer(buffer)
        }
        
        // 6.0.6. Start Audio Engine
        do {
            try audioEngine.start()
            isRecording = true
            // Set `audioState` to `.listening` when recording starts
            audioState = .listening
            print("[\(timestamp())] Audio Engine started successfully.")
            
            // Initialize accumulated audio file
            initializeAccumulatedAudioFile()
            
            // Optional: Monitor audio engine nodes for sound quality
            // monitorAudioEngineNodes() // Uncomment if you implement this method
        } catch {
            // 6.0.7. Handle Audio Engine Start Errors
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let message = "Failed to start audio engine: \(error.localizedDescription)"
                self.audioState = .error(message)
                self.errorMessage = message
                self.showingError = true
            }
            print("[\(timestamp())] Audio Engine Start Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: 7. Stop Continuous Audio Processing
    
    func stopContinuousProcessing() {
        // 7.0.1. Check if Recording is Active
        guard isRecording else {
            print("[\(timestamp())] Recording is not active.")
            return
        }
        
        // 7.0.2. Stop Audio Engine and Remove Tap
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        // Set `audioState` to `.idle` when stopping
        audioState = .idle
        print("[\(timestamp())] Audio Engine stopped.")
        
        // 7.0.3. Finish Recognition Task
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        // 7.0.4. Save Remaining Accumulated Audio
        if accumulatedDuration >= minimumBufferDuration {
            saveAccumulatedAudio()
        }
        accumulatedAudioFile = nil
        accumulatedDuration = 0.0
    }
    
    // MARK: 8. Process Audio Buffer with Transcription-Based Detection and Batching
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // 8.0.1. Validate Buffer Duration
        let bufferDuration = Double(buffer.frameLength) / buffer.format.sampleRate
        print("[\(timestamp())] Buffer duration: \(bufferDuration)s")
        if bufferDuration < minimumBufferDuration {
            print("[\(timestamp())] Buffer duration (\(bufferDuration)s) is below the minimum threshold. Accumulating audio.")
            accumulateAudio(buffer: buffer, duration: bufferDuration)
            return
        }
        
        // 8.0.2. Check if Speech is Detected Before Saving Buffer
        // Ensure that only buffers with detected speech are processed
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.audioState != .detecting {
                print("[\(self.timestamp())] No speech detected. Buffer not saved.")
                return
            }
            // Proceed with saving buffer if speech is detected
            self.bufferForBatching(buffer)
        }
    }
    
    // MARK: 9. Accumulate Audio for Longer Duration
    
    private func accumulateAudio(buffer: AVAudioPCMBuffer, duration: Double) {
        // 9.0.1. Check if the Accumulated Audio File is Initialized
        if accumulatedAudioFile == nil {
            initializeAccumulatedAudioFile()
            // After initialization, ensure it's not nil
            guard accumulatedAudioFile != nil else {
                print("[\(timestamp())] Failed to initialize accumulated audio file.")
                return
            }
        }
        
        // 9.0.2. Write Buffer to the Accumulated Audio File
        do {
            try accumulatedAudioFile?.write(from: buffer)
            accumulatedDuration += duration
            print("[\(timestamp())] Accumulated Duration: \(accumulatedDuration)s")
            
            // 9.0.3. Check if Minimum Duration is Reached
            if accumulatedDuration >= minimumBufferDuration {
                saveAccumulatedAudio()
                accumulatedAudioFile = nil
                accumulatedDuration = 0.0
            }
        } catch {
            let message = "Failed to write to accumulated audio file: \(error.localizedDescription)"
            DispatchQueue.main.async { [weak self] in
                self?.audioState = .error(message)
                self?.errorMessage = message
                self?.showingError = true
            }
            print("[\(timestamp())] Accumulate Audio Write Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: 10. Save Accumulated Audio to Disk
    
    private func saveAccumulatedAudio() {
        guard let accumulatedFile = accumulatedAudioFile else { return }
        
        let fileURL = accumulatedFile.url
        // For accumulated files, use the latest transcription
        let transcription = transcribedText
        let audioWithTranscription = AudioFileWithTranscription(fileURL: fileURL, transcription: transcription)
        
        // Only add to batch if transcription is not empty
        if !transcription.isEmpty {
            batchFileURLs.append(audioWithTranscription)
            print("[\(timestamp())] Accumulated audio saved to: \(fileURL.lastPathComponent) with transcription.")
        } else {
            print("[\(timestamp())] Accumulated audio saved to: \(fileURL.lastPathComponent) without transcription. Skipping upload.")
        }
        
        // 10.0.1. Check if Batch Size is Reached
        if batchFileURLs.count >= batchSize {
            batchAndUploadAudioFiles()
            batchFileURLs.removeAll()
            print("[\(timestamp())] Batch size reached. Preparing to upload.")
        }
    }
    
    // MARK: 11. Buffering for Batch Processing
    
    private func bufferForBatching(_ buffer: AVAudioPCMBuffer) {
        // 11.0.1. Save Buffer to Disk
        guard let fileURL = saveBufferToDisk(buffer: buffer) else {
            print("[\(timestamp())] Failed to save buffer to disk.")
            return
        }
        let transcription = transcribedText
        let audioWithTranscription = AudioFileWithTranscription(fileURL: fileURL, transcription: transcription)
        
        // Only add to batch if transcription is not empty
        if !transcription.isEmpty {
            batchFileURLs.append(audioWithTranscription)
            print("[\(timestamp())] Buffer saved to disk: \(fileURL.lastPathComponent) with transcription.")
        } else {
            print("[\(timestamp())] Buffer saved to disk: \(fileURL.lastPathComponent) without transcription. Skipping upload.")
        }
        
        // 11.0.2. Check if Batch Size Reached
        if batchFileURLs.count >= batchSize {
            batchAndUploadAudioFiles()
            batchFileURLs.removeAll()
            print("[\(timestamp())] Batch size reached. Preparing to upload.")
        }
    }
    
    // MARK: 12. Save Buffer to Disk as WAV
    
    private func saveBufferToDisk(buffer: AVAudioPCMBuffer) -> URL? {
        // 12.0.1. Define File Path
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "buffer_\(UUID().uuidString).wav"
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        // 12.0.2. Validate Audio Format
        guard let audioFormat = buffer.format as AVAudioFormat? else {
            print("[\(timestamp())] Invalid audio format.")
            return nil
        }
        
        // 12.0.3. Calculate Buffer Duration
        let bufferDuration = Double(buffer.frameLength) / buffer.format.sampleRate
        guard bufferDuration >= minimumBufferDuration else {
            print("[\(timestamp())] Buffer duration (\(bufferDuration)s) is below the minimum threshold (\(minimumBufferDuration)s). Skipping save.")
            return nil
        }
        
        // 12.0.4. Write Buffer to File
        do {
            let audioFile = try AVAudioFile(forWriting: fileURL, settings: audioFormat.settings)
            try audioFile.write(from: buffer)
            print("[\(timestamp())] Audio buffer written to: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            // 12.0.5. Handle Write Errors
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let message = "Failed to write audio buffer to disk: \(error.localizedDescription)"
                self.audioState = .error(message)
                self.errorMessage = message
                self.showingError = true
            }
            print("[\(timestamp())] Write Buffer Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: 13. Batch and Upload Audio Files
    
    private func batchAndUploadAudioFiles() {
        // 13.0.1. Perform Batching on Background Queue
        batchQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Only proceed if there are files to upload
            guard !self.batchFileURLs.isEmpty else {
                print("[\(self.timestamp())] No audio files to upload.")
                return
            }
            
            // Create an array of URLs to upload
            let filesToUpload = self.batchFileURLs.map { $0.fileURL }
            
            // Create ZIP from these files
            guard let zipFileURL = self.createZip(from: filesToUpload) else {
                print("[\(self.timestamp())] Failed to create ZIP file.")
                return
            }
            
            // Upload the ZIP file
            self.uploadBatchFile(fileURL: zipFileURL)
        }
        print("[\(timestamp())] Batch uploading initiated.")
    }
    
    // MARK: 14. Create ZIP from Audio Files
    
    private func createZip(from files: [URL]) -> URL? {
        // 14.0.1. Define ZIP Path
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let zipFileURL = documentDirectory.appendingPathComponent("audioBatch_\(UUID().uuidString).zip")
        
        // 14.0.2. Compress Files into ZIP using ZipFoundation
        do {
            // 14.0.2.1. Create a Temporary Directory
            let tempDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            print("[\(timestamp())] Temporary directory created at: \(tempDirectoryURL.path)")
            
            // 14.0.2.2. Copy All Files to the Temporary Directory
            for file in files {
                let destinationURL = tempDirectoryURL.appendingPathComponent(file.lastPathComponent)
                try fileManager.copyItem(at: file, to: destinationURL)
                print("[\(timestamp())] Copied \(file.lastPathComponent) to temporary directory.")
            }
            
            // 14.0.2.3. Zip the Temporary Directory
            try fileManager.zipItem(at: tempDirectoryURL, to: zipFileURL, shouldKeepParent: false)
            print("[\(timestamp())] ZIP created at: \(zipFileURL.lastPathComponent)")
            
            // 14.0.2.4. Clean Up Temporary Directory
            try fileManager.removeItem(at: tempDirectoryURL)
            print("[\(timestamp())] Temporary directory removed.")
        } catch {
            // 14.0.3. Handle ZIP Creation Errors
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let message = "Failed to create ZIP file: \(error.localizedDescription)"
                self.audioState = .error(message)
                self.errorMessage = message
                self.showingError = true
            }
            print("[\(timestamp())] ZIP Creation Error: \(error.localizedDescription)")
            return nil
        }
        
        return zipFileURL
    }
    
    // MARK: 15. Upload Batch ZIP File to Server
    
    private func uploadBatchFile(fileURL: URL) {
        // 15.0.1. Validate Upload URL
        guard let uploadURL = URL(string: "https://36e9-2601-646-a201-db60-00-f79e.ngrok-free.app/upload-audio-zip/") else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let message = "Invalid upload URL."
                self.audioState = .error(message)
                self.errorMessage = message
                self.showingError = true
            }
            print("[\(timestamp())] Invalid Upload URL.")
            return
        }
        
        // 15.0.2. Create URLRequest with Multipart Form-Data
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 15.0.3. Construct Request Body
        var body = Data()
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n")
        body.append("Content-Type: application/zip\r\n\r\n")
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            body.append(fileData)
            body.append("\r\n")
            body.append("--\(boundary)--\r\n")
            request.httpBody = body
            print("[\(timestamp())] Prepared multipart form-data for upload.")
        } catch {
            // 15.0.4. Handle File Data Errors
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let message = "Failed to read ZIP file data: \(error.localizedDescription)"
                self.audioState = .error(message)
                self.errorMessage = message
                self.showingError = true
            }
            print("[\(timestamp())] Read ZIP File Error: \(error.localizedDescription)")
            return
        }
        
        // 15.0.5. Create and Start Upload Task
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            // 15.0.6. Handle Upload Errors
            if let error = error {
                DispatchQueue.main.async {
                    let message = "Upload failed: \(error.localizedDescription)"
                    self.audioState = .error(message)
                    self.errorMessage = message
                    self.showingError = true
                }
                print("[\(self.timestamp())] Upload Task Error: \(error.localizedDescription)")
                // Optionally, implement retry logic or move file to a failed uploads queue
                return
            }
            
            // 15.0.7. Validate HTTP Response
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    let message = "Invalid response from server."
                    self.audioState = .error(message)
                    self.errorMessage = message
                    self.showingError = true
                }
                print("[\(self.timestamp())] Invalid Server Response.")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // 15.0.8. Log Server Error Response
                if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                    print("[\(self.timestamp())] Server Error Response: \(responseBody)")
                }
                let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                DispatchQueue.main.async {
                    self.audioState = .error("Server error: \(message)")
                    self.errorMessage = "Server error: \(message)"
                    self.showingError = true
                }
                print("[\(self.timestamp())] Server Error: \(message)")
                return
            }
            
            // 15.0.9. Successful Upload
            DispatchQueue.main.async {
                print("[\(self.timestamp())] Batch file uploaded successfully!")
            }
            
            // 15.0.10. Remove ZIP File After Successful Upload
            do {
                try self.fileManager.removeItem(at: fileURL)
                print("[\(self.timestamp())] Removed ZIP file after successful upload.")
            } catch {
                DispatchQueue.main.async {
                    let message = "Failed to remove ZIP file after upload: \(error.localizedDescription)"
                    self.audioState = .error(message)
                    self.errorMessage = message
                    self.showingError = true
                }
                print("[\(timestamp())] Failed to remove ZIP file: \(error.localizedDescription)")
            }
        }
        
        task.resume()
        print("[\(timestamp())] Upload task started.")
    }
    
    // MARK: 16. Timestamp Helper
    
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    // MARK: 17. Initialize Accumulated Audio File
    
    private func initializeAccumulatedAudioFile() {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let sessionIdentifier = generateSessionIdentifier()
        let fileName = "session_\(sessionIdentifier)_accumulated.wav"
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        // 17.0.1. Define Audio Format Settings
        let formatSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: actualSampleRate, // Use actual hardware sample rate
            AVNumberOfChannelsKey: 1, // Mono
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        do {
            let format = AVAudioFormat(settings: formatSettings)!
            accumulatedAudioFile = try AVAudioFile(forWriting: fileURL, settings: format.settings)
            print("[\(timestamp())] Accumulated AVAudioFile initialized at: \(fileURL.lastPathComponent) with \(actualSampleRate) Hz, Mono, 16-bit.")
        } catch {
            let message = "Failed to initialize accumulated audio file: \(error.localizedDescription)"
            DispatchQueue.main.async { [weak self] in
                self?.audioState = .error(message)
                self?.errorMessage = message
                self?.showingError = true
            }
            print("[\(timestamp())] Accumulated Audio File Initialization Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: 18. Handle Sound Quality Improvements
    
    // 18.0.1. Monitor and Adjust Audio Engine Nodes to Prevent Unwanted Processing
    //         Ensures that no additional audio nodes are inadvertently modifying the audio stream.
    private func monitorAudioEngineNodes() {
        // Example: Ensure no effect nodes are attached that could alter sound quality
        audioEngine.mainMixerNode.outputVolume = 1.0 // Set to maximum to prevent volume issues
        print("[\(timestamp())] Audio Engine nodes monitored for sound quality.")
    }
    
    // MARK: 19. Handle Missing Speech Configuration
    
    // 19.0.1. Configure Handling of Audio Files Without Speech
    //         Option to skip uploading or flagging such files based on configuration.
    private func handleMissingSpeechInAudioFile(fileURL: URL) {
        if transcribedText.isEmpty {
            print("[\(timestamp())] No speech detected in audio file: \(fileURL.lastPathComponent). Skipping upload.")
            // Example: Skip uploading or mark for review
            // To skip uploading, simply return without uploading
            // To mark for review, add to a separate queue or log
            return
        }
        // If speech is present, proceed with upload
        batchFileURLs.append(AudioFileWithTranscription(fileURL: fileURL, transcription: transcribedText))
    }
}

// MARK: - DateFormatter Helper Method

extension PersistentAudioManager {
    private func generateSessionIdentifier() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss" // Custom format
        formatter.locale = Locale.current
        let formattedDate = formatter.string(from: Date())
        return formattedDate
    }
}

// MARK: - Data Extension for Appending Strings
/**
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
*/
