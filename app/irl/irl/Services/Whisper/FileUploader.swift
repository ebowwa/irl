//
//  FileUploader.swift
//  irl
//
//  Created by Elijah Arbee on 9/8/24.
//
import Foundation
import Combine

class FileUploader {
    static func uploadFile(url: URL, task: TaskEnum, language: LanguageEnum) -> AnyPublisher<String, Error> {
        Future<String, Error> { promise in
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
                
                promise(.success(audioUrl))
            }.resume()
        }.eraseToAnyPublisher()
    }
}
