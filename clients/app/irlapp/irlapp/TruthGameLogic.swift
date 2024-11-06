// TruthGameLogic.swift
import SwiftUI
import Combine
import AVFoundation

// MARK: 1. Data Models

/// 1.1. Represents the analysis of an individual statement.
struct StatementAnalysis: Identifiable, Decodable {
    let id: Int
    let statement: String // Mapped from 'text' in JSON
    let isTruth: Bool
    let pitchVariation: String
    let pauseDuration: Double
    let stressLevel: String
    let confidenceScore: Double

    // Mapping JSON keys to struct properties
    enum CodingKeys: String, CodingKey {
        case id
        case statement = "text" 
        case isTruth
        case pitchVariation
        case pauseDuration
        case stressLevel
        case confidenceScore
    }
}

/// 1.2. Represents the overall analysis response containing multiple statements.
struct AnalysisResponse: Decodable {
    let finalConfidenceScore: Double
    let guessJustification: String
    let likelyLieStatementId: Int // Refers to the `id` of the likely lie
    let responseMessage: String
    let statementIds: [Int]
    let statements: [StatementAnalysis]
}

// MARK: 2. Error Wrapper

/// 2.1. A simple wrapper to make error messages identifiable.
struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: 3. Service Class

/// 3.1. Manages the analysis data, business logic, and audio recording.
class AnalysisService: NSObject, ObservableObject {
    // 3.2. Published properties to notify the UI of data changes.
    @Published var response: AnalysisResponse?
    @Published var statements: [StatementAnalysis] = []
    @Published var swipedStatements: Set<Int> = [] // Tracks swiped statements by their IDs
    @Published var showSummary: Bool = false
    @Published var isRecording: Bool = false
    @Published var isPlaying: Bool = false
    @Published var recordedURL: URL?
    @Published var recordingError: ErrorWrapper? // Updated to use ErrorWrapper

    private var cancellables = Set<AnyCancellable>()
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?

    // MARK: 4. Initialization

    /// 4.1. Initializes the service and requests microphone access.
    override init() {
        super.init()
        requestMicrophoneAccess()
    }

    // MARK: 5. Microphone Access

    /// 5.1. Requests permission to access the microphone.
    private func requestMicrophoneAccess() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    self.recordingError = ErrorWrapper(message: "Microphone access is required to record statements.")
                }
            }
        }
    }

    // MARK: 6. Recording Functions

    /// 6.1. Starts recording audio in WAV format.
    func startRecording() {
        let recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [])
            try recordingSession.setActive(true)

            // Updated settings for WAV format
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false
            ]

            let filename = getDocumentsDirectory().appendingPathComponent("recorded_statement.wav") // Updated to .wav
            audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            DispatchQueue.main.async {
                self.isRecording = true
                self.recordedURL = filename
            }
        } catch {
            DispatchQueue.main.async {
                self.recordingError = ErrorWrapper(message: "Failed to start recording: \(error.localizedDescription)")
            }
        }
    }

    /// 6.2. Stops recording audio.
    func stopRecording() {
        audioRecorder?.stop()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    /// 6.3. Plays the recorded audio.
    func playRecording() {
        guard let url = recordedURL else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            DispatchQueue.main.async {
                self.isPlaying = true
            }
        } catch {
            DispatchQueue.main.async {
                self.recordingError = ErrorWrapper(message: "Failed to play recording: \(error.localizedDescription)")
            }
        }
    }

    /// 6.4. Stops playing audio.
    func stopPlaying() {
        audioPlayer?.stop()
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }

    // MARK: 7. Upload Function

    /// 7.1. Uploads the recorded audio to the backend for analysis.
    func uploadRecording() {
        guard let url = recordedURL else {
            self.recordingError = ErrorWrapper(message: "No recording found to upload.")
            return
        }

        guard let uploadURL = URL(string: "https://695c-2601-646-a201-db60-00-a3c1.ngrok-free.app/TruthNLie") else {
            self.recordingError = ErrorWrapper(message: "Invalid upload URL.")
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Note: 'Content-Type' for multipart/form-data is set automatically by URLSession

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Prepare multipart/form-data body
        var body = Data()
        let filename = url.lastPathComponent
        let mimeType = "audio/wav" // Updated MIME type for WAV

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        if let fileData = try? Data(contentsOf: url) {
            body.append(fileData)
        } else {
            DispatchQueue.main.async {
                self.recordingError = ErrorWrapper(message: "Failed to read the recorded file.")
            }
            return
        }
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        // Create a URLSession upload task
        URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.recordingError = ErrorWrapper(message: "Upload failed: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.recordingError = ErrorWrapper(message: "No data received from server.")
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                let analysisResponse = try decoder.decode(AnalysisResponse.self, from: data)
                DispatchQueue.main.async {
                    self.response = analysisResponse
                    self.setupStatements()
                }
            } catch {
                // Print the error for debugging purposes
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed to decode JSON response: \(jsonString)")
                }
                print("Decoding error: \(error)")
                DispatchQueue.main.async {
                    self.recordingError = ErrorWrapper(message: "Failed to parse response: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    // MARK: 8. Setup Functions

    /// 8.1. Sets up the statements array based on the analysis response.
    func setupStatements() {
        guard let response = response else { return }

        // Find the likely lie based on likelyLieStatementId.
        guard let likelyLie = response.statements.first(where: { $0.id == response.likelyLieStatementId }) else {
            // If not found, use all statements as-is.
            statements = response.statements
            return
        }

        // Separate other statements excluding the likely lie.
        let otherStatements = response.statements.filter { $0.id != response.likelyLieStatementId }

        // Combine all statements with the likely lie first and last.
        statements = [likelyLie] + otherStatements + [likelyLie]
    }

    // MARK: 9. Swipe Handling

    /// 9.1. Handles the swipe action by updating the swipedStatements set and checking if summary should be shown.
    /// - Parameters:
    ///   - direction: The direction in which the card was swiped.
    ///   - statement: The specific statement that was swiped.
    func handleSwipe(direction: SwipeDirection, for statement: StatementAnalysis) {
        // Add the swiped statement's ID to the swipedStatements set.
        swipedStatements.insert(statement.id)

        // Check if all statements have been swiped.
        if swipedStatements.count == statements.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    self.showSummary = true
                }
            }
        }
    }

    // MARK: 10. Reset Function

    /// 10.1. Resets all swiped statements, allowing users to revisit the cards.
    func resetSwipes() {
        withAnimation {
            swipedStatements.removeAll()
            showSummary = false
            response = nil
            statements.removeAll()
            recordedURL = nil
        }
    }

    // MARK: 11. Helper Functions

    /// 11.1. Retrieves the documents directory URL.
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: 12. Swipe Direction Enum

    /// 12.1. Enum to represent swipe directions.
    enum SwipeDirection {
        case left, right
    }
}

// MARK: 13. AVAudioRecorder Delegate

extension AnalysisService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            recordingError = ErrorWrapper(message: "Recording was not successful.")
        }
    }
}

// MARK: 14. AVAudioPlayer Delegate

extension AnalysisService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}
