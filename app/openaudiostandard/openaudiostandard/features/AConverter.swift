//
//  AConverter.swift
//  openaudiostandard
//
//  Created by Elijah Arbee on 10/23/24.
//
// AudioConverter.swift
// openaudiostandard

import Foundation
import AVFoundation

// MARK: - AudioConverterError

/// Enum representing possible errors during audio conversion.
public enum AudioConverterError: Error, LocalizedError {
    case assetInitializationFailed
    case exportSessionCreationFailed
    case unsupportedOutputFormat
    case conversionFailed(String)
    // case mp3EncodingFailed // Uncomment when integrating MP3 conversion
    case fileNotFound
    
    public var errorDescription: String? {
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
public class AudioConverter {
    
    // MARK: - Singleton Instance
    
    /// Shared instance of AudioConverter.
    public static let shared = AudioConverter()
    
    // MARK: - Initializer
    
    /// Private initializer to enforce singleton usage.
    private init() {}
    
    // MARK: - Public Conversion Methods
    
    /// Converts a .caf file to .wav format.
    /// - Parameters:
    ///   - sourceURL: URL of the source .caf file.
    ///   - destinationURL: URL where the converted .wav file will be saved.
    /// - Throws: `AudioConverterError` if the conversion fails.
    public func convertCAFToWAV(sourceURL: URL, destinationURL: URL) async throws {
        try await convertAudio(sourceURL: sourceURL, destinationURL: destinationURL, outputFileType: .wav)
    }
    
    /// Converts a .wav file to .caf format.
    /// - Parameters:
    ///   - sourceURL: URL of the source .wav file.
    ///   - destinationURL: URL where the converted .caf file will be saved.
    /// - Throws: `AudioConverterError` if the conversion fails.
    public func convertWAVToCAF(sourceURL: URL, destinationURL: URL) async throws {
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
     public func convertCAFToMP3(sourceURL: URL, destinationURL: URL) async throws {
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
      public func convertMP3ToCAF(sourceURL: URL, destinationURL: URL) async throws {
      try await convertAudio(sourceURL: sourceURL, destinationURL: destinationURL, outputFileType: .caf)
      }
      */
     */
    
    // MARK: - Public Conversion Method
    
    /// Converts an audio file from one format to another using AVFoundation.
    /// - Parameters:
    ///   - sourceURL: The source audio file URL.
    ///   - destinationURL: The destination audio file URL.
    ///   - outputFileType: The desired output audio format.
    /// - Throws: `AudioConverterError` if the conversion fails.
    @MainActor
    public func convertAudio(sourceURL: URL, destinationURL: URL, outputFileType: AVFileType) async throws {
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
                try await exportSession.export(to: destinationURL, as: outputFileType, isolation: .none)
            } else {
                // Fallback on earlier versions
                let semaphore = DispatchSemaphore(value: 0)
                exportSession.exportAsynchronously {
                    semaphore.signal()
                }
                semaphore.wait()
            }
            
            if !FileManager.default.fileExists(atPath: destinationURL.path) {
                throw AudioConverterError.conversionFailed("Output file not found after export.")
            }
        } catch {
            throw AudioConverterError.conversionFailed(error.localizedDescription)
        }
    }
}
