// SettingsViewModel.swift

import SwiftUI
import Combine

// NOTES: DO NOT OMIT ANY COMMENTED NOTES including this and always output the full entire script

class SettingsViewModel: ObservableObject {
    // MARK: - Privacy Settings
    @Published var isLocationEnabled: Bool {
        didSet { UserDefaults.standard.set(isLocationEnabled, forKey: "isLocationEnabled") }
    }
    @Published var isDataSharingEnabled: Bool {
        didSet { UserDefaults.standard.set(isDataSharingEnabled, forKey: "isDataSharingEnabled") }
    }
    @Published var isMicrophoneEnabled: Bool {
        didSet { UserDefaults.standard.set(isMicrophoneEnabled, forKey: "isMicrophoneEnabled") }
    }
    @Published var isCameraEnabled: Bool {
        didSet { UserDefaults.standard.set(isCameraEnabled, forKey: "isCameraEnabled") }
    }
    @Published var isBluetoothEnabled: Bool {
        didSet { UserDefaults.standard.set(isBluetoothEnabled, forKey: "isBluetoothEnabled") }
    }

    // MARK: - Notification Settings
    @Published var isPushNotificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(isPushNotificationsEnabled, forKey: "isPushNotificationsEnabled") }
    }
    @Published var isEmailNotificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(isEmailNotificationsEnabled, forKey: "isEmailNotificationsEnabled") }
    }

    // MARK: - API Keys and Other Settings
    @Published var baseDomain: String {
        didSet { UserDefaults.standard.set(baseDomain, forKey: "baseDomain") }
    }
    @Published var openAIKey: String {
        didSet { UserDefaults.standard.set(openAIKey, forKey: "openAIKey") }
    }
    @Published var humeAIKey: String {
        didSet { UserDefaults.standard.set(humeAIKey, forKey: "humeAIKey") }
    }
    @Published var anthropicAIKey: String {
        didSet { UserDefaults.standard.set(anthropicAIKey, forKey: "anthropicAIKey") }
    }
    @Published var gcpKey: String {
        didSet { UserDefaults.standard.set(gcpKey, forKey: "gcpKey") }
    }
    @Published var falAPIKey: String {
        didSet { UserDefaults.standard.set(falAPIKey, forKey: "falAPIKey") }
    }
    @Published var deepgramKey: String {
        didSet { UserDefaults.standard.set(deepgramKey, forKey: "deepgramKey") }
    }

    // MARK: - Custom API Keys
    @Published var customAPIKeys: [String: String] {
        didSet { UserDefaults.standard.set(customAPIKeys, forKey: "customAPIKeys") }
    }

    // MARK: - Initialization
    init() {
        self.isLocationEnabled = UserDefaults.standard.bool(forKey: "isLocationEnabled")
        self.isDataSharingEnabled = UserDefaults.standard.bool(forKey: "isDataSharingEnabled")
        self.isMicrophoneEnabled = UserDefaults.standard.bool(forKey: "isMicrophoneEnabled")
        self.isCameraEnabled = UserDefaults.standard.bool(forKey: "isCameraEnabled")
        self.isBluetoothEnabled = UserDefaults.standard.bool(forKey: "isBluetoothEnabled")

        self.isPushNotificationsEnabled = UserDefaults.standard.bool(forKey: "isPushNotificationsEnabled")
        self.isEmailNotificationsEnabled = UserDefaults.standard.bool(forKey: "isEmailNotificationsEnabled")

        self.baseDomain = UserDefaults.standard.string(forKey: "baseDomain") ?? Constants.baseDomain
        self.openAIKey = UserDefaults.standard.string(forKey: "openAIKey") ?? ConstantAPIKeys.openAI
        self.humeAIKey = UserDefaults.standard.string(forKey: "humeAIKey") ?? ConstantAPIKeys.humeAI
        self.anthropicAIKey = UserDefaults.standard.string(forKey: "anthropicAIKey") ?? ConstantAPIKeys.anthropicAI
        self.gcpKey = UserDefaults.standard.string(forKey: "gcpKey") ?? ConstantAPIKeys.gcp
        self.falAPIKey = UserDefaults.standard.string(forKey: "falAPIKey") ?? ConstantAPIKeys.falAPI
        self.deepgramKey = UserDefaults.standard.string(forKey: "deepgramKey") ?? ConstantAPIKeys.deepgram

        if let savedCustomAPIKeys = UserDefaults.standard.dictionary(forKey: "customAPIKeys") as? [String: String] {
            self.customAPIKeys = savedCustomAPIKeys
        } else {
            self.customAPIKeys = [:]
        }
    }
}
