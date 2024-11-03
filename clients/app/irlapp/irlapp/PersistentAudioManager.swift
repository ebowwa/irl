import Foundation
import AVFoundation
import Combine
import UIKit
import ZIPFoundation

// MARK: - PersistentAudioManager

class PersistentAudioManager: NSObject, ObservableObject {
    // MARK: 1. Properties
    
    // 1.1. Audio Engine and Queues
    private let audioEngine = AVAudioEngine()
    private let batchQueue = DispatchQueue(label: "com.caringmind.batchQueue", qos: .background)
    
    // 1.2. Recording State
    private var isRecording = false
    private var audioBuffer: AVAudioPCMBuffer?
    
    // 1.3. Background Task Management
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    // 1.4. File Management
    private let fileManager = FileManager.default
    private var batchFileURLs = [URL]()
    
    // 1.5. Published Properties for UI Updates
    @Published var isSpeechDetected: Bool = false
    @Published var errorMessage: String?
    
    // 1.6. Published Property for Showing Errors
    @Published var showingError: Bool = false
    
    // 1.7. Voice Activity Detection (VAD) Initialization
    private let vad = EnergyBasedVoiceActivityDetector()
    
    // 1.8. Batch Size Configuration
    private let batchSize = 10 // Number of buffers per batch
    
    // MARK: 2. Initialization
    
    override init() {
        super.init()
        configureAudioSession()
        setupNotifications()
    }
    
    // MARK: 3. Audio Session Configuration
    
    private func configureAudioSession() {
        // 3.0.1. Set Category and Mode
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
            try audioSession.setActive(true)
            print("[\(timestamp())] Audio session configured successfully.")
        } catch {
            // 3.0.2. Handle Configuration Errors
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Failed to configure audio session: \(error.localizedDescription)"
                self.showingError = true
            }
            print("[\(timestamp())] Audio Session Configuration Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: 4. Notification Setup for Background Tasks
    
    private func setupNotifications() {
        // 4.0.1. Observe App Entering Background
        NotificationCenter.default.addObserver(self, selector: #selector(startBackgroundTask), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // 4.0.2. Observe App Entering Foreground
        NotificationCenter.default.addObserver(self, selector: #selector(endBackgroundTask), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc private func startBackgroundTask() {
        // 4.1.1. Begin Background Task
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
            print("[\(self.timestamp())] Background task ended by system.")
        }
        print("[\(timestamp())] Background task started.")
    }
    
    @objc private func endBackgroundTask() {
        // 4.2.1. End Background Task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
            print("[\(timestamp())] Background task ended.")
        }
    }
    
    // MARK: 5. Start Continuous Audio Processing
    
    func startContinuousProcessing() {
        // 5.0.1. Prevent Multiple Recordings
        guard !isRecording else {
            print("[\(timestamp())] Already recording.")
            return
        }
        
        let inputNode = audioEngine.inputNode
        let bufferSize: AVAudioFrameCount = 1024
        let format = inputNode.outputFormat(forBus: 0)
        
        // 5.0.2. Install Tap on Audio Node
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.handleLiveProcessing(buffer: buffer)
            self.bufferForBatching(buffer)
        }
        
        // 5.0.3. Start Audio Engine
        do {
            try audioEngine.start()
            isRecording = true
            print("[\(timestamp())] Audio Engine started successfully.")
        } catch {
            // 5.0.4. Handle Audio Engine Start Errors
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
                self.showingError = true
            }
            print("[\(timestamp())] Audio Engine Start Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: 6. Stop Continuous Audio Processing
    
    func stopContinuousProcessing() {
        // 6.0.1. Check if Recording is Active
        guard isRecording else {
            print("[\(timestamp())] Recording is not active.")
            return
        }
        
        // 6.0.2. Stop Audio Engine and Remove Tap
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isRecording = false
        print("[\(timestamp())] Audio Engine stopped.")
    }
    
    // MARK: 7. Live Processing of Audio Buffers
    
    private func handleLiveProcessing(buffer: AVAudioPCMBuffer) {
        // 7.0.1. Perform VAD on Buffer
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let speechDetected = self.vad.isSpeech(buffer: buffer)
            if speechDetected {
                DispatchQueue.main.async {
                    self.isSpeechDetected = true
                    print("[\(self.timestamp())] Speech detected.")
                    // Optional: Trigger UI updates or other actions here
                }
            } else {
                DispatchQueue.main.async {
                    self.isSpeechDetected = false
                    print("[\(self.timestamp())] No speech detected.")
                }
            }
        }
    }
    
    // MARK: 8. Buffering for Batch Processing
    
    private func bufferForBatching(_ buffer: AVAudioPCMBuffer) {
        // 8.0.1. Save Buffer to Disk
        let fileURL = saveBufferToDisk(buffer: buffer)
        batchFileURLs.append(fileURL)
        print("[\(timestamp())] Buffer saved to disk: \(fileURL.lastPathComponent)")
        
        // 8.0.2. Check if Batch Size Reached
        if batchFileURLs.count >= batchSize {
            batchAndUploadAudioFiles()
            batchFileURLs.removeAll()
            print("[\(timestamp())] Batch size reached. Preparing to upload.")
        }
    }
    
    // MARK: 9. Save Buffer to Disk as WAV
    
    private func saveBufferToDisk(buffer: AVAudioPCMBuffer) -> URL {
        // 9.0.1. Define File Path
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "buffer_\(UUID().uuidString).wav"
        let fileURL = documentDirectory.appendingPathComponent(fileName)
        
        // 9.0.2. Validate Audio Format
        guard let audioFormat = buffer.format as AVAudioFormat? else {
            print("[\(timestamp())] Invalid audio format.")
            return fileURL
        }
        
        // 9.0.3. Write Buffer to File
        do {
            let audioFile = try AVAudioFile(forWriting: fileURL, settings: audioFormat.settings)
            try audioFile.write(from: buffer)
            print("[\(timestamp())] Audio buffer written to: \(fileURL.lastPathComponent)")
        } catch {
            // 9.0.4. Handle Write Errors
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Failed to write audio buffer to disk: \(error.localizedDescription)"
                self.showingError = true
            }
            print("[\(timestamp())] Write Buffer Error: \(error.localizedDescription)")
        }
        
        return fileURL
    }
    
    // MARK: 10. Batch and Upload Audio Files
    
    private func batchAndUploadAudioFiles() {
        // 10.0.1. Perform Batching on Background Queue
        batchQueue.async { [weak self] in
            guard let self = self else { return }
            let zipFileURL = self.createZip(from: self.batchFileURLs)
            self.uploadBatchFile(fileURL: zipFileURL)
        }
        print("[\(timestamp())] Batch uploading initiated.")
    }
    
    // MARK: 11. Create ZIP from Audio Files
    
    private func createZip(from files: [URL]) -> URL {
        // 11.0.1. Define ZIP Path
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let zipFileURL = documentDirectory.appendingPathComponent("audioBatch_\(UUID().uuidString).zip")
        
        // 11.0.2. Compress Files into ZIP using ZipFoundation
        do {
            // **11.0.2.1. Create a Temporary Directory**
            let tempDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            print("[\(timestamp())] Temporary directory created at: \(tempDirectoryURL.path)")
            
            // **11.0.2.2. Move All Files to the Temporary Directory**
            for file in files {
                let destinationURL = tempDirectoryURL.appendingPathComponent(file.lastPathComponent)
                try fileManager.moveItem(at: file, to: destinationURL)
                print("[\(timestamp())] Moved \(file.lastPathComponent) to temporary directory.")
            }
            
            // **11.0.2.3. Zip the Temporary Directory**
            try fileManager.zipItem(at: tempDirectoryURL, to: zipFileURL, shouldKeepParent: false)
            print("[\(timestamp())] ZIP created at: \(zipFileURL.lastPathComponent)")
            
            // **11.0.2.4. Clean Up Temporary Directory**
            try fileManager.removeItem(at: tempDirectoryURL)
            print("[\(timestamp())] Temporary directory removed.")
        } catch {
            // 11.0.3. Handle ZIP Creation Errors
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Failed to create ZIP file: \(error.localizedDescription)"
                self.showingError = true
            }
            print("[\(timestamp())] ZIP Creation Error: \(error.localizedDescription)")
        }
        
        return zipFileURL
    }
    
    // MARK: 12. Upload Batch ZIP File to Server
    
    private func uploadBatchFile(fileURL: URL) {
        // 12.0.1. Validate Upload URL
        guard let uploadURL = URL(string: "https://your-server-url.com/upload-audio-zip/") else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Invalid upload URL."
                self.showingError = true
            }
            print("[\(timestamp())] Invalid Upload URL.")
            return
        }
        
        // 12.0.2. Create URLRequest with Multipart Form-Data
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 12.0.3. Construct Request Body
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
            // 12.0.4. Handle File Data Errors
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Failed to read ZIP file data: \(error.localizedDescription)"
                self.showingError = true
            }
            print("[\(timestamp())] Read ZIP File Error: \(error.localizedDescription)")
            return
        }
        
        // 12.0.5. Create and Start Upload Task
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            // 12.0.6. Handle Upload Errors
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Upload failed: \(error.localizedDescription)"
                    self.showingError = true
                }
                print("[\(self.timestamp())] Upload Task Error: \(error.localizedDescription)")
                return
            }
            
            // 12.0.7. Validate HTTP Response
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid response from server."
                    self.showingError = true
                }
                print("[\(self.timestamp())] Invalid Server Response.")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // 12.0.8. Log Server Error Response
                if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                    print("[\(self.timestamp())] Server Error Response: \(responseBody)")
                }
                let message = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                DispatchQueue.main.async {
                    self.errorMessage = "Server error: \(message)"
                    self.showingError = true
                }
                print("[\(self.timestamp())] Server Error: \(message)")
                return
            }
            
            // 12.0.9. Successful Upload
            DispatchQueue.main.async {
                print("[\(self.timestamp())] Batch file uploaded successfully!")
            }
            
            // 12.0.10. Optionally, Remove ZIP File After Successful Upload
            do {
                try self.fileManager.removeItem(at: fileURL)
                print("[\(self.timestamp())] Removed ZIP file after successful upload.")
            } catch {
                print("[\(self.timestamp())] Failed to remove ZIP file: \(error.localizedDescription)")
            }
        }
        
        task.resume()
        print("[\(timestamp())] Upload task started.")
    }
    
    // MARK: 13. Timestamp Helper
    
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
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
