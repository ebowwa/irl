//
//  ConfigurationAndStorage.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
import Foundation

struct Configuration: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let parameters: ChatParametersViewModel
    let isDraft: Bool
    let createdAt: Date
    let updatedAt: Date

    init(title: String, description: String, parameters: ChatParametersViewModel, isDraft: Bool) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.parameters = parameters
        self.isDraft = isDraft
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct LocalStorage {
    static func saveConfiguration(_ config: Configuration) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(config) {
            UserDefaults.standard.set(encoded, forKey: "savedConfig_\(config.id.uuidString)")
            var savedIds = UserDefaults.standard.stringArray(forKey: "savedConfigIds") ?? []
            if !savedIds.contains(config.id.uuidString) {
                savedIds.append(config.id.uuidString)
                UserDefaults.standard.set(savedIds, forKey: "savedConfigIds")
            }
        }
    }

    static func loadConfiguration(withId id: UUID) -> Configuration? {
        if let savedConfig = UserDefaults.standard.object(forKey: "savedConfig_\(id.uuidString)") as? Data {
            let decoder = JSONDecoder()
            if let loadedConfig = try? decoder.decode(Configuration.self, from: savedConfig) {
                return loadedConfig
            }
        }
        return nil
    }

    static func getAllConfigurations() -> [Configuration] {
        let savedIds = UserDefaults.standard.stringArray(forKey: "savedConfigIds") ?? []
        return savedIds.compactMap { UUID(uuidString: $0) }.compactMap { loadConfiguration(withId: $0) }
    }

    static func deleteConfiguration(withId id: UUID) {
        UserDefaults.standard.removeObject(forKey: "savedConfig_\(id.uuidString)")
        var savedIds = UserDefaults.standard.stringArray(forKey: "savedConfigIds") ?? []
        savedIds.removeAll { $0 == id.uuidString }
        UserDefaults.standard.set(savedIds, forKey: "savedConfigIds")
    }
}
