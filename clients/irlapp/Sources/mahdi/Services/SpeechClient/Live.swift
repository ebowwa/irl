import AVFoundation
import Dependencies
import Speech

extension SpeechClient {
    static let live = Self(
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
                    recognizer.recognitionTask(with: request) { result, error in
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
        finishTask: {
            // Implementation for finishing the task
        }
    )
}
