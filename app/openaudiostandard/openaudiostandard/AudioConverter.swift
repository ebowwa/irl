//
//  AudioConverter.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/22/24.
//

import Foundation
import AVFoundation

// MARK: - AudioConverterError

/// Enum representing possible errors during audio conversion.
enum AudioConverterError: Error, LocalizedError {
    case assetInitializationFailed
    case exportSessionCreationFailed
    case unsupportedOutputFormat
    case conversionFailed(String)
    // case mp3EncodingFailed // Uncomment when integrating MP3 conversion
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .assetInitializationFailed:
            return "Failed to initialize the audio asset."
        case .exportSessionCreationFailed:
            return "Failed to create the export session."
        case .unsupportedOutputFormat:
            return "The specified output format is unsupported."
        case .conversionFailed(let message):
            return "Conversion failed: \(message)"
        // case .mp3EncodingFailed:
        //     return "MP3 encoding failed."
        case .fileNotFound:
            return "The specified file was not found."
        }
    }
}

// MARK: - AudioConverter

/// A singleton class responsible for converting audio files between .caf and .wav formats.
/// Future support for .mp3 will be added using the LAME library.
class AudioConverter {
    
    // MARK: - Singleton Instance
    
    /// Shared instance of AudioConverter.
    static let shared = AudioConverter()
    
    // MARK: - Initializer
    
    /// Private initializer to enforce singleton usage.
    private init() {}
    
    // MARK: - Public Conversion Methods
    
    /// Converts a .caf file to .wav format.
    /// - Parameters:
    ///   - sourceURL: URL of the source .caf file.
    ///   - destinationURL: URL where the converted .wav file will be saved.
    /// - Throws: `AudioConverterError` if the conversion fails.
    func convertCAFToWAV(sourceURL: URL, destinationURL: URL) async throws {
        try await convertAudio(sourceURL: sourceURL, destinationURL: destinationURL, outputFileType: .wav)
    }
    
    /// Converts a .wav file to .caf format.
    /// - Parameters:
    ///   - sourceURL: URL of the source .wav file.
    ///   - destinationURL: URL where the converted .caf file will be saved.
    /// - Throws: `AudioConverterError` if the conversion fails.
    func convertWAVToCAF(sourceURL: URL, destinationURL: URL) async throws {
        try await convertAudio(sourceURL: sourceURL, destinationURL: destinationURL, outputFileType: .caf)
    }
    
    /// Converts a .caf file to .mp3 format.
    /// - Parameters:
    ///   - sourceURL: URL of the source .caf file.
    ///   - destinationURL: URL where the converted .mp3 file will be saved.
    /// - Throws: `AudioConverterError` if the conversion fails.
    /// - Note: This method is currently commented out. To enable MP3 conversion, integrate the LAME library
    ///         and uncomment the relevant code sections below.
    /*
     func convertCAFToMP3(sourceURL: URL, destinationURL: URL) async throws {
     try await convertAudioToMP3(sourceURL: sourceURL, destinationURL: destinationURL)
     }
     
     /// Converts a .mp3 file to .caf format.
     /// - Parameters:
     ///   - sourceURL: URL of the source .mp3 file.
     ///   - destinationURL: URL where the converted .caf file will be saved.
     /// - Throws: `AudioConverterError` if the conversion fails.
     /// - Note: This method is currently commented out. To enable MP3 conversion, integrate the LAME library
     ///         and uncomment the relevant code sections below.
     /*
      func convertMP3ToCAF(sourceURL: URL, destinationURL: URL) async throws {
      try await convertAudio(sourceURL: sourceURL, destinationURL: destinationURL, outputFileType: .caf)
      }
      */
     */
    
    // MARK: - Private Conversion Methods
    
    /// General method to convert audio files using AVFoundation with async/await.
    /// - Parameters:
    ///   - sourceURL: URL of the source audio file.
    ///   - destinationURL: URL where the converted file will be saved.
    ///   - outputFileType: Desired output file type (e.g., .wav, .caf).
    /// - Throws: `AudioConverterError` if the conversion fails.
    @MainActor
    private func convertAudio(sourceURL: URL, destinationURL: URL, outputFileType: AVFileType) async throws {
        let asset = AVURLAsset(url: sourceURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw AudioConverterError.exportSessionCreationFailed
        }
        
        exportSession.outputFileType = outputFileType
        exportSession.outputURL = destinationURL

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        do {
            if #available(iOS 18, *) {
                try await exportSession.export(to: destinationURL, as: .wav, isolation: .none)
            }

            if !FileManager.default.fileExists(atPath: destinationURL.path) {
                throw AudioConverterError.conversionFailed("Output file not found after export.")
            }
        } catch {
            throw AudioConverterError.conversionFailed(error.localizedDescription)
        }
    }

        
        
        /// Converts audio files to MP3 format using the LAME library.
        /// - Parameters:
        ///   - sourceURL: URL of the source audio file (supports .caf and .wav).
        ///   - destinationURL: URL where the converted .mp3 file will be saved.
        /// - Throws: `AudioConverterError` if the conversion fails.
        /// - Note: This method is currently commented out. To enable MP3 conversion, integrate the LAME library
        ///         and uncomment the relevant code sections below.
        /*
         private func convertAudioToMP3(sourceURL: URL, destinationURL: URL) async throws {
         // Implementation for MP3 conversion using LAME would go here.
         // This includes reading the source file, setting up the LAME encoder, encoding the audio data,
         // and writing the MP3 data to the destination URL.
         
         // Example steps:
         // 1. Initialize AVAudioFile for reading the source audio.
         // 2. Set up LAME encoder with appropriate settings.
         // 3. Read audio data into a buffer.
         // 4. Encode the buffer to MP3 format.
         // 5. Write the encoded MP3 data to the destination URL.
         // 6. Handle errors and clean up resources.
         
         // Since MP3 conversion is not currently required, this method is left unimplemented.
         throw AudioConverterError.unsupportedOutputFormat
         }
         */
    }
    
    // MARK: - Future Integration Instructions for MP3 Conversion
    
    /*
     # Integrating LAME Library for MP3 Conversion
     
     To enable MP3 conversion in the `AudioConverter` framework, follow these steps:
     
     1. **Download LAME Library**:
     - Obtain the LAME library source code from [LAME's official website](https://lame.sourceforge.io/) or use a precompiled version suitable for iOS/watchOS.
     
     2. **Add LAME to Your Xcode Project**:
     - Drag the `libmp3lame.a` (static library) and `lame.h` (header file) into your Xcode project.
     - Ensure they are added to the appropriate targets (iOS and watchOS).
     
     3. **Create a Bridging Header**:
     - If your project doesn't have one, create a new Objective-C file. Xcode will prompt you to create a bridging header. Confirm to create it.
     - Add the following line to the bridging header (e.g., `YourProject-Bridging-Header.h`):
     ```objc
     #include "lame.h"
     ```
     
     4. **Link Binary Libraries**:
     - Go to your project’s **Build Phases** > **Link Binary With Libraries**.
     - Add `libmp3lame.a`.
     
     5. **Configure Build Settings**:
     - Ensure **Header Search Paths** include the path to `lame.h`.
     - Set **Enable Modules (C and Objective-C)** to `Yes`.
     
     6. **Uncomment MP3 Conversion Code**:
     - In `AudioConverter.swift`, uncomment the MP3 conversion methods and related error cases.
     - Implement the `convertAudioToMP3` method with proper encoding logic using the LAME library.
     
     7. **Handle Licensing**:
     - LAME is licensed under the LGPL. Ensure your app's usage complies with this license, especially if your app is proprietary.
     
     8. **Testing**:
     - Thoroughly test MP3 conversion functionality on all target devices (iOS and watchOS) to ensure compatibility and performance.
     
     By following these steps, you can seamlessly integrate MP3 conversion capabilities into the `AudioConverter` framework, expanding its functionality for future use cases.
     */

