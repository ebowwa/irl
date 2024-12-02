import Foundation

enum AppConfig {
    // MARK: - Authentication
    enum Auth {
        static let googleClientId = "YOUR_CLIENT_ID" // Replace with actual client ID
        static let keychainService = "com.caringmind.app"
        static let keychainAccount = "auth"
    }

    // MARK: - API
    enum API {
        static let baseURL = "https://api.caringmind.com" // Replace with actual API URL
        static let version = "v1"
    }

    // MARK: - Audio
    enum Audio {
        static let maxRecordingDuration: TimeInterval = 300 // 5 minutes
        static let sampleRate: Double = 44100
        static let channelCount: Int = 1
        static let bitDepth: Int = 16
    }

    // MARK: - Storage
    enum Storage {
        static let maxAudioFileSize: Int64 = 50 * 1024 * 1024 // 50MB
        static let audioDirectory = "audio_recordings"
        static let transcriptDirectory = "transcripts"
    }

    // MARK: - UI
    enum UI {
        static let minimumPasswordLength = 8
        static let maximumNameLength = 50
        static let defaultAnimationDuration: Double = 0.3
    }

    // MARK: - Error Messages
    enum ErrorMessages {
        static let genericError = "Something went wrong. Please try again."
        static let networkError = "Please check your internet connection and try again."
        static let authError = "Authentication failed. Please try again."
        static let audioError = "There was an issue with audio recording. Please try again."
    }
}
