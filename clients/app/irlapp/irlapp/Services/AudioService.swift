//
//  AudioService.swift
//  mahdi
//
//  Created by Elijah Arbee on 11/22/24.
//

import Foundation
import Combine
import AVFoundation

// MARK: - Models

struct ProcessAudioResponse: Codable {
    let results: [AudioResult]
}
// TODO: this defined type means i cannot just throw in any prompt we need to configure prompts to map to AudioData and redefine AudioData for other results
// TODO: Full view development then removale of recording button
struct AudioResult: Codable, Identifiable {
    let id = UUID() // Unique identifier for SwiftUI's ForEach
    let file: String
    let status: String
    let data: AudioData
    let file_uris: [String]
}

struct AudioData: Codable {
    let clarity: String
    let emotional_undertones: String
    let environment_context: String
    let pronunciation_accuracy: String
    let speech_patterns: SpeechPatterns
    let transcription: String
}

struct SpeechPatterns: Codable {
    let pace: String
    let tone: String
    let volume: String
}

// MARK: - AudioService

class AudioService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    // MARK: - Published Properties
    @Published var uploadStatus: String = "Idle"
    @Published var liveTranscriptions: [AudioResult] = []
    @Published var historicalTranscriptions: [AudioResult] = []
    @Published var isRecording: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = Constants.baseURL // Ensure this is correctly set in Constants.swift
    private let pollingInterval: TimeInterval = 10.0 // Poll every 10 seconds
    private var pollingTimer: Timer?
    
    // MARK: - Audio Recorder
    private var audioRecorder: AVAudioRecorder?
    private var recordedFileURL: URL?
    
    // MARK: - Initialization
    override init() {
        super.init()
        requestAudioPermission()
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
    
    // MARK: - Audio Recording Methods
    
    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            let timestamp = Date().timeIntervalSince1970
            let filename = getDocumentsDirectory().appendingPathComponent("recording_\(Int(timestamp)).m4a")
            audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            recordedFileURL = filename
            isRecording = true
            uploadStatus = "Recording..."
            
            // Start polling when recording starts (if polling is necessary)
            // Commented out to prevent 405 errors
            // startPolling()
            
            print("Recording started. File saved at: \(filename.path)")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
            uploadStatus = "Recording failed"
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        uploadStatus = "Stopped Recording"
        
        // Stop polling when recording stops (if polling was started)
        // Commented out to prevent 405 errors
        // stopPolling()
        
        // Upload the recorded file
        if let fileURL = recordedFileURL {
            uploadAudio(files: [fileURL])
        } else {
            print("No recorded file URL found.")
            uploadStatus = "No audio file to upload"
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Audio Permission
    
    private func requestAudioPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.uploadStatus = "Audio Recording Permission Denied"
                    print("Audio recording permission denied.")
                } else {
                    print("Audio recording permission granted.")
                }
            }
        }
    }
    
    // MARK: - Upload Audio
    
    /// Uploads audio files to the server.
    /// - Parameter files: Array of local file URLs to upload.
    func uploadAudio(files: [URL]) {
        guard let googleAccountId = KeychainHelper.standard.getGoogleAccountID() else {
            uploadStatus = "Missing Google Account ID"
            print("Upload Error: Missing Google Account ID")
            return
        }
        
        let deviceUUID = DeviceUUID.getUUID()
        let promptType = "detailed_analysis"
        let batch = "false" // Must be a string to match query parameters in the URL
    
        // Construct the full endpoint with query parameters
        guard let baseURL = URL(string: baseURL),
              var components = URLComponents(url: baseURL.appendingPathComponent("/onboarding/v8/process-audio"), resolvingAgainstBaseURL: false) else {
            uploadStatus = "Invalid Server URL"
            print("Upload Error: Invalid Server URL")
            return
        }
        components.queryItems = [
            URLQueryItem(name: "google_account_id", value: googleAccountId),
            URLQueryItem(name: "device_uuid", value: deviceUUID),
            URLQueryItem(name: "prompt_type", value: promptType),
            URLQueryItem(name: "batch", value: batch)
        ]
        
        guard let finalURL = components.url else {
            uploadStatus = "Failed to construct URL"
            print("Upload Error: Failed to construct URL")
            return
        }
    
        // Create a multipart form-data request
        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Generate a unique boundary for multipart data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create the HTTP body
        let httpBody = createMultipartBody(with: files, boundary: boundary)
        request.httpBody = httpBody
    
        // Debugging: Print request details
        print("Upload Request URL: \(request.url?.absoluteString ?? "No URL")")
        print("HTTP Method: \(request.httpMethod ?? "No HTTP Method")")
        print("Headers: \(request.allHTTPHeaderFields ?? [:])")
        print("Body size: \(httpBody.count) bytes")
    
        // Perform the upload using Combine
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                if !(200..<300).contains(httpResponse.statusCode) {
                    let statusCode = httpResponse.statusCode
                    let responseString = String(data: output.data, encoding: .utf8) ?? "Unable to parse response body"
                    print("Upload Error - HTTP \(statusCode): \(responseString)")
                    throw URLError(.init(rawValue: statusCode))
                }
                return output.data
            }
            .decode(type: ProcessAudioResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    self.uploadStatus = "Upload Successful"
                    print("Upload Successful")
                case .failure(let error):
                    print("Upload Error: \(error.localizedDescription)")
                    self.uploadStatus = "Upload Failed: \(error.localizedDescription)"
                }
            }, receiveValue: { response in
                self.liveTranscriptions.append(contentsOf: response.results)
                print("Received Transcription Results: \(response.results)")
            })
            .store(in: &cancellables)
    }
    
    /// Creates a multipart/form-data body with the provided files.
    /// - Parameters:
    ///   - files: Array of file URLs to include in the form data.
    ///   - boundary: Boundary string for separating parts.
    /// - Returns: Data representing the multipart/form-data body.
    private func createMultipartBody(with files: [URL], boundary: String) -> Data {
        var body = Data()
        
        for fileURL in files {
            let filename = fileURL.lastPathComponent
            let mimeType = "audio/ogg" // Ensure MIME type matches your files
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimeType)\r\n\r\n")
            
            do {
                let fileData = try Data(contentsOf: fileURL)
                body.append(fileData)
                body.append("\r\n")
                print("Appended file: \(filename)")
            } catch {
                print("Failed to read file at \(fileURL.path): \(error.localizedDescription)")
            }
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
            uploadStatus = "Recording Failed"
            print("Audio Recorder did not finish recording successfully.")
        } else {
            print("Audio Recorder finished recording successfully.")
        }
    }
}
