//
//  IrlAudioConfigLoader.swift
//  irl
//
//  Created by Elijah Arbee on 10/7/24.
//
import Foundation

/// Utility class to load audio configurations from JSON files.
class IrlAudioConfigLoader {
    /// Loads the audio configuration from a bundled JSON file.
    /// - Parameters:
    ///   - filename: Name of the JSON file (without extension).
    ///   - fileExtension: Extension of the JSON file.
    /// - Returns: An instance of `IrlAudioConfiguration` if successful; otherwise, nil.
    static func loadConfiguration(from filename: String, withExtension fileExtension: String) -> IrlAudioConfiguration? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("IrlAudioConfigLoader: Could not find \(filename).\(fileExtension) in the bundle.")
            return nil
        }

        return loadConfiguration(from: url)
    }

    /// Loads the audio configuration from a specified URL.
    /// - Parameter url: The file URL of the JSON configuration.
    /// - Returns: An instance of `IrlAudioConfiguration` if successful; otherwise, nil.
    static func loadConfiguration(from url: URL) -> IrlAudioConfiguration? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(IrlAudioConfiguration.self, from: data)
            print("IrlAudioConfigLoader: Successfully loaded configuration from \(url).")
            return configuration
        } catch {
            print("IrlAudioConfigLoader: Failed to load configuration from \(url) with error: \(error).")
            return nil
        }
    }

    /// Saves the audio configuration to a specified URL as JSON.
    /// - Parameters:
    ///   - configuration: The `IrlAudioConfiguration` instance to save.
    ///   - url: The file URL where the JSON should be saved.
    /// - Returns: A boolean indicating success or failure.
    static func saveConfiguration(_ configuration: IrlAudioConfiguration, to url: URL) -> Bool {
        guard let jsonData = configuration.toJSONData() else {
            print("IrlAudioConfigLoader: Failed to convert configuration to JSON data.")
            return false
        }

        do {
            try jsonData.write(to: url, options: [.atomicWrite])
            print("IrlAudioConfigLoader: Successfully saved configuration to \(url).")
            return true
        } catch {
            print("IrlAudioConfigLoader: Failed to save configuration to \(url) with error: \(error).")
            return false
        }
    }
}
