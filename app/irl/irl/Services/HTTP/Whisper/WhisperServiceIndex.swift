//
//  WhisperService.swift
//  irl
//  Backend currently uses FAL AI
//  Created by Elijah Arbee on 9/8/24.
//
import Foundation
import Combine

class WhisperService: ObservableObject {
    @Published var output: WhisperOutput = WhisperOutput(text: "", chunks: [])
    @Published var isLoading: Bool = false

    private var webSocketTask: URLSessionWebSocketTask?
    var cancellables = Set<AnyCancellable>()

    func uploadFile(url: URL, task: TaskEnum, language: LanguageEnum) -> AnyPublisher<Void, Error> {
        FileUploader.uploadFile(url: url, task: task, language: language)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.isLoading = true
            }, receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .flatMap { [weak self] audioUrl -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "WhisperService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Self is nil"])).eraseToAnyPublisher()
                }
                self.connectWebSocket(audioUrl: audioUrl, task: task, language: language)
                return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func connectWebSocket(audioUrl: String, task: TaskEnum, language: LanguageEnum) {
        WebSocketHandler.connectWebSocket(audioUrl: audioUrl, task: task, language: language) { [weak self] result in
            switch result {
            case .success(let output):
                DispatchQueue.main.async {
                    self?.output = output
                    self?.isLoading = false
                }
            case .failure(let error):
                print("WebSocket error: \(error)")
                DispatchQueue.main.async {
                    self?.isLoading = false
                }
            }
        }
    }
}
