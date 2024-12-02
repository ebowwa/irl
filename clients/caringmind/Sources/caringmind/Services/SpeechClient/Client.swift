import AVFoundation
import Dependencies
import Speech

struct SpeechClient {
    var requestAuthorization: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus
    var startTask: @Sendable (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) async throws -> SFSpeechRecognitionResult
    var finishTask: @Sendable () async -> Void

    enum Failure: LocalizedError, Equatable {
        case notAvailable
        case recognitionFailed(Error)
        case taskError
        case couldntStartAudioEngine

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Speech recognition is not available on this device."
            case .recognitionFailed(let error):
                return "Speech recognition failed: \(error.localizedDescription)"
            case .taskError:
                return "Could not create speech recognition task."
            case .couldntStartAudioEngine:
                return "Could not start audio engine."
            }
        }

        static func == (lhs: SpeechClient.Failure, rhs: SpeechClient.Failure) -> Bool {
            switch (lhs, rhs) {
            case (.notAvailable, .notAvailable):
                return true
            case let (.recognitionFailed(lhsError), .recognitionFailed(rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            case (.taskError, .taskError):
                return true
            case (.couldntStartAudioEngine, .couldntStartAudioEngine):
                return true
            default:
                return false
            }
        }
    }
}

extension SpeechClient: DependencyKey {
    static let liveValue = Self(
        requestAuthorization: {
            await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
        },
        startTask: { audioEngine, request in
            try await withCheckedThrowingContinuation { continuation in
                guard let recognizer = SFSpeechRecognizer() else {
                    continuation.resume(throwing: Failure.notAvailable)
                    return
                }

                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)

                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    request.append(buffer)
                }

                do {
                    try audioEngine.start()
                    _ = recognizer.recognitionTask(with: request) { result, error in
                        if let error = error {
                            continuation.resume(throwing: Failure.recognitionFailed(error))
                            return
                        }
                        if let result = result, result.isFinal {
                            continuation.resume(returning: result)
                        }
                    }
                } catch {
                    continuation.resume(throwing: Failure.couldntStartAudioEngine)
                }
            }
        },
        finishTask: { }
    )

    static let testValue = Self(
        requestAuthorization: { .authorized },
        startTask: { _, _ in
            try await withCheckedThrowingContinuation { continuation in
                guard let recognizer = SFSpeechRecognizer() else {
                    continuation.resume(throwing: Failure.notAvailable)
                    return
                }

                let request = SFSpeechAudioBufferRecognitionRequest()
                _ = recognizer.recognitionTask(with: request) { result, error in
                    if let error = error {
                        continuation.resume(throwing: Failure.recognitionFailed(error))
                        return
                    }
                    if let result = result, result.isFinal {
                        continuation.resume(returning: result)
                    }
                }
            }
        },
        finishTask: { }
    )

    static var previewValue: Self {
        let isRecording = LockIsolated(false)

        return Self(
            requestAuthorization: { .authorized },
            startTask: { _, _ in
                try await withCheckedThrowingContinuation { continuation in
                    Task {
                        isRecording.setValue(true)

                        guard let recognizer = SFSpeechRecognizer() else {
                            continuation.resume(throwing: Failure.notAvailable)
                            return
                        }

                        let request = SFSpeechAudioBufferRecognitionRequest()
                        request.shouldReportPartialResults = true

                        recognizer.recognitionTask(with: request) { result, error in
                            if let error = error {
                                continuation.resume(throwing: Failure.recognitionFailed(error))
                                return
                            }
                            if let result = result, result.isFinal {
                                continuation.resume(returning: result)
                            }
                        }
                    }
                }
            },
            finishTask: { isRecording.setValue(false) }
        )
    }
}

extension DependencyValues {
    var speechClient: SpeechClient {
        get { self[SpeechClient.self] }
        set { self[SpeechClient.self] = newValue }
    }
}
