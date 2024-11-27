//
//  AudioService.swift
//  mahdi
//
//  Created by Elijah Arbee on 11/22/24.
//

import Foundation
import Combine
import AVFoundation
import MobileCoreServices
import UniformTypeIdentifiers

// MARK: - AnyCodable

/// A type-erased `Codable` value.
/// (No changes here)
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    // Decoding initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Attempt to decode various types
        if let intValue = try? container.decode(Int.self) {
            self.value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            self.value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            self.value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            self.value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            self.value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            var dictionary: [String: Any] = [:]
            for (key, anyCodable) in dictValue {
                dictionary[key] = anyCodable.value
            }
            self.value = dictionary
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode AnyCodable")
        }
    }

    // Encoding method
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            let encodableArray = arrayValue.map { AnyCodable($0) }
            try container.encode(encodableArray)
        case let dictValue as [String: Any]:
            let encodableDict = dictValue.mapValues { AnyCodable($0) }
            try container.encode(encodableDict)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - Models

struct ProcessAudioResponse: Codable {
    let results: [AudioResult]
}

struct AudioResult: Codable, Identifiable {
    let id = UUID() // Unique identifier for SwiftUI's ForEach
    let file: String
    let status: String
    let data: [String: AnyCodable]
    let file_uris: [String]
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
        startRecording()
        startPolling()
    }

    deinit {
        pollingTimer?.invalidate()
        audioRecorder?.stop()
    }

    // MARK: - Audio Recording Methods

    private func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatOpus), // OGG with Opus encoding
                AVSampleRateKey: 48000, // Common sample rate for Opus
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let timestamp = Date().timeIntervalSince1970
            let filename = getDocumentsDirectory().appendingPathComponent("recording_\(Int(timestamp)).ogg")
            audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            recordedFileURL = filename
            isRecording = true
            uploadStatus = "Recording..."

            print("Recording started. File saved at: \(filename.path)")
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
            uploadStatus = "Recording failed"
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        uploadStatus = "Stopped Recording"

        // Prepare for next recording
        audioRecorder = nil
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

    // MARK: - Polling Methods

    private func startPolling() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.handlePolling()
        } // NOTES: this will be redefined to use the apple speech ml and noise analytics; including speech detected bool
        RunLoop.current.add(pollingTimer!, forMode: .common)
        print("Polling started with interval: \(pollingInterval) seconds")
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        print("Polling stopped.")
    }

    private func handlePolling() {
        print("Polling triggered.")
        guard let fileURL = recordedFileURL else {
            print("No audio file to upload.")
            return
        }

        // Stop current recording
        stopRecording()

        // Upload the recorded file
        uploadAudio(files: [fileURL])

        // Start a new recording
        startRecording()
    }

    // MARK: - Upload Audio

    /// Uploads audio files to the server.
    /// - Parameter files: Array of local file URLs to upload.
    private func uploadAudio(files: [URL]) {
        guard let googleAccountId = KeychainHelper.standard.getGoogleAccountID() else {
            uploadStatus = "Missing Google Account ID"
            print("Upload Error: Missing Google Account ID")
            return
        }

        let deviceUUID = DeviceUUID.getUUID()
        let promptType = "detailed_analysis"
        // TODO: define the prompt type response structure alongside prompt type, but maybe this is inputted more at the view model level to match level of ui decisions
        let batch = "false" // Must be a string to match query parameters in the URL

        // Construct the full endpoint with query parameters
        guard let baseURL = URL(string: baseURL),
              var components = URLComponents(url: baseURL.appendingPathComponent("/production/v1/process-audio"), resolvingAgainstBaseURL: false) else {
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
            let mimeType = mimeTypeForPath(path: fileURL.path)

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

    /// Determines the MIME type based on the file extension.
    /// - Parameter path: File path.
    /// - Returns: Corresponding MIME type as a string.
    private func mimeTypeForPath(path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension.lowercased()

        switch pathExtension {
        case "aac":
            return "audio/aac"
        case "flac":
            return "audio/flac"
        case "aiff":
            return "audio/aiff"
        case "wav":
            return "audio/wav"
        case "mp3":
            return "audio/mp3"
        case "ogg":
            return "audio/ogg"
        default:
            return "application/octet-stream"
        }
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
