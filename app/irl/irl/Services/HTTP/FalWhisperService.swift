//
//  FalWhisperService.swift
//  irl
//
//  Created by Elijah Arbee on 9/2/24.
//
import Foundation
import Combine

class WhisperService: ObservableObject {
    @Published var output: WhisperOutput = WhisperOutput(text: "", chunks: [])
    @Published var isLoading: Bool = false

    private var webSocketTask: URLSessionWebSocketTask?
    var cancellables = Set<AnyCancellable>()

    func uploadFile(url: URL, task: TaskEnum, language: LanguageEnum) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            self.isLoading = true

            let boundary = UUID().uuidString
            var request = URLRequest(url: URL(string: Constants.API.baseURL + Constants.API.Paths.upload)!)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            let data = try? Data(contentsOf: url)
            guard let fileData = data else {
                promise(.failure(NSError(domain: "WhisperService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load file data"])))
                return
            }

            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(url.lastPathComponent)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

            URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                guard let data = data,
                      let json = try? JSONDecoder().decode([String: String].self, from: data),
                      let audioUrl = json["url"] else {
                    promise(.failure(NSError(domain: "WhisperService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get audio URL from server"])))
                    return
                }
                
                self.connectWebSocket(audioUrl: audioUrl, task: task, language: language)
                promise(.success(()))
            }.resume()
        }.eraseToAnyPublisher()
    }

    private func connectWebSocket(audioUrl: String, task: TaskEnum, language: LanguageEnum) {
        guard let url = URL(string: Constants.API.webSocketBaseURL + Constants.API.Paths.whisperTTS) else { return }
        
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessage()
        
        let message = WhisperInput(audio_url: audioUrl, task: task, language: language)
        sendMessage(message)
    }

    private func sendMessage(_ message: WhisperInput) {
        guard let encodedMessage = try? JSONEncoder().encode(message),
              let messageString = String(data: encodedMessage, encoding: .utf8) else { return }
        
        webSocketTask?.send(.string(messageString)) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("Error in receiving message: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let decodedMessage = try? JSONDecoder().decode(WhisperOutput.self, from: data) {
                        DispatchQueue.main.async {
                            self.output = decodedMessage
                            self.isLoading = false
                        }
                    }
                case .data(let data):
                    // Handle binary data if needed
                    break
                @unknown default:
                    break
                }
                self.receiveMessage()
            }
        }
    }
}

// Existing struct and enum definitions remain unchanged
struct WhisperInput: Codable {
    let audio_url: String
    let task: TaskEnum
    let language: LanguageEnum
    var chunk_level: ChunkLevelEnum = .segment
    var version: VersionEnum = .v3
}

struct WhisperOutput: Codable {
    let text: String
    let chunks: [WhisperChunk]
}

struct WhisperChunk: Codable, Identifiable {
    var id = UUID()
    let timestamp: [Float]
    let text: String
}

enum TaskEnum: String, Codable, CaseIterable {
    case transcribe
    case translate
}

enum LanguageEnum: String, Codable, CaseIterable {
    case af, am, ar, as_, az, ba, be, bg, bn, bo, br, bs, ca, cs, cy, da, de, el, en, es, et, eu, fa, fi, fo, fr, gl, gu, ha, haw, he, hi, hr, ht, hu, hy, id, is_, it, ja, jw, ka, kk, km, kn, ko, la, lb, ln, lo, lt, lv, mg, mi, mk, ml, mn, mr, ms, mt, my, ne, nl, nn, no, oc, pa, pl, ps, pt, ro, ru, sa, sd, si, sk, sl, sn, so, sq, sr, su, sv, sw, ta, te, tg, th, tk, tl, tr, tt, uk, ur, uz, vi, yi, yo, yue, zh
}

enum ChunkLevelEnum: String, Codable {
    case segment
}

enum VersionEnum: String, Codable {
    case v3 = "3"
}
