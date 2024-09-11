//
//  WhisperService.swift
//  irl
//  Backend currently uses FAL AI
//  Created by Elijah Arbee on 9/8/24.
//

import Foundation
import Combine

/// WhisperService: Main class for managing audio file processing and WebSocket communication
///
/// This class serves as the primary interface for the Whisper functionality in the app.
/// It handles file uploading, WebSocket connections, and state management.
///
/// SCALING AND EXTENSION CONSIDERATIONS:
/// 1. Error Handling: Implement a more robust error handling system, possibly with custom error types.
/// 2. Dependency Injection: Consider injecting dependencies (e.g., FileUploader, WebSocketHandler) for better testability.
/// 3. Cancellation: Implement cancellation logic for ongoing processes.
/// 4. Progress Tracking: Add more granular progress tracking for long-running operations.
/// 5. Caching: Implement a caching mechanism for processed audio to reduce API calls.
/// 6. Retry Logic: Add retry mechanisms for failed network requests.
class WhisperService: ObservableObject {
    /// Published properties for SwiftUI integration
    @Published var output: WhisperOutput = WhisperOutput(text: "", chunks: [])
    @Published var isLoading: Bool = false

    /// Set to store cancellables for memory management
    public var cancellables = Set<AnyCancellable>()

    /// Uploads an audio file and initiates the WebSocket connection for processing
    ///
    /// - Parameters:
    ///   - url: The local URL of the audio file to be processed
    ///   - task: The type of task to perform (e.g., transcribe, translate)
    ///   - language: The language of the audio or target language for translation
    ///
    /// - Returns: A publisher that completes when the process is finished or emits an error
    ///
    /// IMPROVEMENT IDEAS:
    /// - Add progress tracking for file upload
    /// - Implement retry logic for failed uploads
    /// - Consider adding a parameter for custom API options
    func uploadFile(url: URL, task: TaskEnum, language: AppLanguage) -> AnyPublisher<Void, Error> {
        guard let languageEnum = convertToLanguageEnum(language) else {
            return Fail(error: NSError(domain: "WhisperService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid language code"])).eraseToAnyPublisher()
        }

        return FileUploader.uploadFile(url: url, task: task, language: languageEnum)
            .handleEvents(receiveSubscription: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isLoading = true
                }
            }, receiveCompletion: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            })
            .receive(on: DispatchQueue.main)  // Ensure we're on the main thread
            .flatMap { [weak self] audioUrl -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "WhisperService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])).eraseToAnyPublisher()
                }
                self.connectWebSocket(audioUrl: audioUrl, task: task, language: languageEnum)
                return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Establishes a WebSocket connection for processing the uploaded audio file
    ///
    /// - Parameters:
    ///   - audioUrl: The URL of the uploaded audio file on the server
    ///   - task: The type of task to perform
    ///   - language: The language for processing
    ///
    /// IMPROVEMENT IDEAS:
    /// - Implement reconnection logic for dropped WebSocket connections
    /// - Add timeout handling for long-running processes
    /// - Consider moving WebSocket logic to a separate manager class for better separation of concerns
    private func connectWebSocket(audioUrl: String, task: TaskEnum, language: LanguageEnum) {
        WebSocketHandler.connectWebSocket(audioUrl: audioUrl, task: task, language: language) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let output):
                    self?.output = output
                    self?.isLoading = false
                case .failure(let error):
                    print("WebSocket error: \(error)")
                    self?.isLoading = false
                    // TODO: Implement proper error handling and user notification
                }
            }
        }
    }

    /// Converts AppLanguage to LanguageEnum
    ///
    /// - Parameter appLanguage: The AppLanguage to convert
    /// - Returns: The corresponding LanguageEnum, or nil if not found
    ///
    /// IMPROVEMENT IDEAS:
    /// - Consider using a more robust mapping system, possibly with a dictionary
    /// - Add logging for unsupported language codes
    /// - Handle cases where AppLanguage doesn't have a direct LanguageEnum equivalent
    private func convertToLanguageEnum(_ appLanguage: AppLanguage) -> LanguageEnum? {
        return LanguageEnum(rawValue: appLanguage.code)
    }
}

// MARK: - Potential Extensions and Improvements

/// TODO: Implement cancellation functionality
extension WhisperService {
    func cancelOngoingProcess() {
        // Implement logic to cancel ongoing uploads or WebSocket connections
    }
}

/// TODO: Add more granular progress tracking
extension WhisperService {
    func trackProgress() {
        // Implement progress tracking for file upload and processing
    }
}

/// TODO: Implement caching mechanism
extension WhisperService {
    func cacheProcessedAudio() {
        // Implement caching logic for processed audio to reduce API calls
    }
}

/// TODO: Add retry logic for failed requests
extension WhisperService {
    func retryFailedRequest() {
        // Implement retry logic for failed network requests
    }
}

// MARK: - Testing Considerations

/// For better testability:
/// 1. Use dependency injection for FileUploader and WebSocketHandler
/// 2. Create protocols for network operations to allow for easy mocking
/// 3. Implement a test-specific configuration to bypass actual network calls

// MARK: - Notes on Backend

/// NOTE: The current backend uses FAL AI
/// When updating or switching backends:
/// 1. Ensure the new backend supports the same features (transcription, translation)
/// 2. Update the FileUploader and WebSocketHandler to match the new API requirements
/// 3. Verify that the LanguageEnum and TaskEnum are compatible with the new backend
/// 4. Update error handling to account for any new error types from the new backend
/// 5. Consider creating an abstraction layer to make future backend changes easier
