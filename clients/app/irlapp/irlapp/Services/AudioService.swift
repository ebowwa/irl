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

// MARK: - Models

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
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
            self.value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode AnyCodable")
        }
    }

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
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

struct ProcessAudioResponse: Codable {
    let results: [AudioResult]?
}

struct AudioResult: Codable, Identifiable {
    let id = UUID()
    let file: String       // Made non-optional
    let status: String     // Made non-optional
    let data: [String: AnyCodable]
    let file_uri: String   // Made non-optional
    let stored: Bool       // Made non-optional

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
    private let baseURL = Constants.baseURL
    private let pollingInterval: TimeInterval = 30.0
    private var pollingTimer: Timer?
    private let maxLiveTranscriptions = 50
    private let maxHistoricalTranscriptions = 100
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
                AVFormatIDKey: Int(kAudioFormatOpus),
                AVSampleRateKey: 48000,
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
        audioRecorder = nil
    }

    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Audio Permission

    private func requestAudioPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if !granted {
                    self?.uploadStatus = "Audio Recording Permission Denied"
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
        }
        RunLoop.current.add(pollingTimer!, forMode: .common)
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func handlePolling() {
        guard let fileURL = recordedFileURL else {
            print("No audio file to upload.")
            return
        }

        stopRecording()
        uploadAudio(files: [fileURL])
        startRecording()
    }

    // MARK: - Upload Audio

    private func uploadAudio(files: [URL]) {
        guard let googleAccountId = KeychainHelper.standard.getGoogleAccountID() else {
            uploadStatus = "Missing Google Account ID"
            return
        }

        let deviceUUID = DeviceUUID.getUUID()
        let promptType = "transcription_v1"
        let batch = "false"

        guard let baseURL = URL(string: baseURL),
              var components = URLComponents(url: baseURL.appendingPathComponent("/production/v1/process-audio"), resolvingAgainstBaseURL: false) else {
            uploadStatus = "Invalid Server URL"
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
            return
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let httpBody = createMultipartBody(with: files, boundary: boundary)
        request.httpBody = httpBody

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output -> Data in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                if !(200..<300).contains(httpResponse.statusCode) {
                    throw NSError(domain: "ServerError",
                                code: httpResponse.statusCode,
                                userInfo: [NSLocalizedDescriptionKey: String(data: output.data, encoding: .utf8) ?? "Unknown error"])
                }
                return output.data
            }
            .decode(type: ProcessAudioResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.uploadStatus = "Upload Failed: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    if let results = response.results {
                        self.liveTranscriptions.append(contentsOf: results)
                        if self.liveTranscriptions.count > self.maxLiveTranscriptions {
                            self.liveTranscriptions.removeFirst(self.liveTranscriptions.count - self.maxLiveTranscriptions)
                        }
                        self.uploadStatus = "Upload Successful"
                    } else {
                        self.uploadStatus = "Upload Successful but no results"
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func createMultipartBody(with files: [URL], boundary: String) -> Data {
        var body = Data()

        for fileURL in files {
            let filename = fileURL.lastPathComponent
            let mimeType = mimeTypeForPath(path: fileURL.path)

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimeType)\r\n\r\n")

            if let fileData = try? Data(contentsOf: fileURL) {
                body.append(fileData)
                body.append("\r\n")
            }
        }

        body.append("--\(boundary)--\r\n")
        return body
    }

    private func mimeTypeForPath(path: String) -> String {
        let pathExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        
        switch pathExtension {
        case "aac": return "audio/aac"
        case "flac": return "audio/flac"
        case "aiff": return "audio/aiff"
        case "wav": return "audio/wav"
        case "mp3": return "audio/mp3"
        case "ogg": return "audio/ogg"
        default: return "application/octet-stream"
        }
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
            uploadStatus = "Recording Failed"
        }
    }
}
