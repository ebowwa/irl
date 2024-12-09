import Foundation
import AVFoundation

// MARK: - Protocols
protocol AudioRecordingService {
    var isRecording: Bool { get }
    func startRecording() throws
    func stopRecording()
    func getRecordedAudioURL() -> URL?
}

protocol AudioUploadService {
    func uploadAudio(from url: URL) async throws -> ServerResponse
}

protocol InputNameServiceProtocol: AudioRecordingService, AudioUploadService {
    var showError: Bool { get set }
    var errorMessage: String? { get set }
}

// MARK: - Error Types
enum AudioRecordingError: LocalizedError {
    case failedToCreateFileURL
    case recordingSetupFailed(Error)
    case noRecordingFound
    
    var errorDescription: String? {
        switch self {
        case .failedToCreateFileURL:
            return "Failed to create audio file URL"
        case .recordingSetupFailed(let error):
            return "Recording setup failed: \(error.localizedDescription)"
        case .noRecordingFound:
            return "No recording found"
        }
    }
}

// MARK: - Main Service Implementation
class InputNameService: NSObject, InputNameServiceProtocol, ObservableObject {
    @Published var isRecording = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private let backendURL: URL
    private let audioSession: AVAudioSession
    
    init(backendURL: URL = URL(string: "https://9419-2a01-4ff-f0-b1f6-00-1.ngrok-free.app/onboarding/v3/process-audio")!,
         audioSession: AVAudioSession = .sharedInstance()) {
        self.backendURL = backendURL
        self.audioSession = audioSession
        super.init()
    }
    
    // MARK: - AudioRecordingService Implementation
    func startRecording() throws {
        do {
            try setupAudioSession()
            try setupAndStartRecorder()
            isRecording = true
        } catch {
            throw AudioRecordingError.recordingSetupFailed(error)
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }
    
    func getRecordedAudioURL() -> URL? {
        return audioFileURL
    }
    
    // MARK: - AudioUploadService Implementation
    func uploadAudio(from url: URL) async throws -> ServerResponse {
        var request = try createUploadRequest(for: url)
        return try await performUpload(with: request)
    }
    
    // For backward compatibility
    func uploadAudioFile() async throws -> ServerResponse {
        guard let fileURL = audioFileURL else {
            throw AudioRecordingError.noRecordingFound
        }
        return try await uploadAudio(from: fileURL)
    }
}

// MARK: - AVAudioRecorderDelegate
extension InputNameService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            showError = true
            errorMessage = "Recording failed to complete successfully"
        }
    }
}

// MARK: - Private Helper Methods
private extension InputNameService {
    func setupAudioSession() throws {
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
    }
    
    func setupAndStartRecorder() throws {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "recordedAudio_\(UUID().uuidString).wav"
        audioFileURL = documents.appendingPathComponent(fileName)
        
        guard let fileURL = audioFileURL else {
            throw AudioRecordingError.failedToCreateFileURL
        }
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.record()
    }
    
    func createUploadRequest(for fileURL: URL) throws -> URLRequest {
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        
        let audioData = try Data(contentsOf: fileURL)
        data.append(audioData)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        return request
    }
    
    func performUpload(with request: URLRequest) async throws -> ServerResponse {
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        return try decoder.decode(ServerResponse.self, from: responseData)
    }
}
