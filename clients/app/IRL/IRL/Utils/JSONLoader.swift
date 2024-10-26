//
//  JSONLoader.swift
//  irl
//
//  Created by Elijah Arbee on 10/2/24.
//
import Foundation

enum JSONLoaderError: Error {
    case fileNotFound(String)
    case decodingFailed(Error)
}

struct JSONLoader {
    static func load<T: Decodable>(
        from filename: String,
        fileExtension: String = "json",
        bundle: Bundle = .main,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    ) -> Result<T, JSONLoaderError> {
        guard let url = bundle.url(forResource: filename, withExtension: fileExtension) else {
            return .failure(.fileNotFound("\(filename).\(fileExtension)"))
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = dateDecodingStrategy
            decoder.keyDecodingStrategy = keyDecodingStrategy
            let decodedData = try decoder.decode(T.self, from: data)
            return .success(decodedData)
        } catch {
            return .failure(.decodingFailed(error))
        }
    }
}
