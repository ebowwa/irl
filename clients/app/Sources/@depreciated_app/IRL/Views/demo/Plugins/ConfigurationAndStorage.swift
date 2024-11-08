//
//  ConfigurationAndStorage.swift
//  irl
//
//  Created by Elijah Arbee on 9/9/24.
//
//  This file defines the Configuration model and LocalStorage utility for managing configurations.
//  Configurations are currently saved using UserDefaults, with plans to integrate SQL for enhanced functionality.
//

import Foundation

// MARK: - Configuration Model

/// Represents a chat configuration with various parameters.
struct Configuration: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let parameters: ChatParametersViewModel
    let isDraft: Bool
    let createdAt: Date
    let updatedAt: Date
    
    /// Initializes a new Configuration.
    /// - Parameters:
    ///   - title: The title of the configuration.
    ///   - description: A description of the configuration.
    ///   - parameters: The chat parameters associated with the configuration.
    ///   - isDraft: Indicates if the configuration is a draft.
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

// MARK: - LocalStorage Utility

/// Utility for saving, loading, and managing configurations.
struct LocalStorage {
    /// Saves a configuration to UserDefaults.
    /// - Parameter config: The Configuration to save.
    static func saveConfiguration(_ config: Configuration) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(config) {
            // Save the encoded configuration data with a unique key.
            UserDefaults.standard.set(encoded, forKey: "savedConfig_\(config.id.uuidString)")
            
            // Retrieve existing saved configuration IDs or initialize an empty array.
            var savedIds = UserDefaults.standard.stringArray(forKey: "savedConfigIds") ?? []
            
            // Add the new configuration ID if it's not already present.
            if !savedIds.contains(config.id.uuidString) {
                savedIds.append(config.id.uuidString)
                UserDefaults.standard.set(savedIds, forKey: "savedConfigIds")
            }
        }
    }
    
    /// Loads a configuration from UserDefaults using its UUID.
    /// - Parameter id: The UUID of the Configuration to load.
    /// - Returns: The loaded Configuration, if available.
    static func loadConfiguration(withId id: UUID) -> Configuration? {
        if let savedConfig = UserDefaults.standard.object(forKey: "savedConfig_\(id.uuidString)") as? Data {
            let decoder = JSONDecoder()
            if let loadedConfig = try? decoder.decode(Configuration.self, from: savedConfig) {
                return loadedConfig
            }
        }
        return nil
    }
    
    /// Retrieves all saved configurations.
    /// - Returns: An array of Configuration objects.
    static func getAllConfigurations() -> [Configuration] {
        let savedIds = UserDefaults.standard.stringArray(forKey: "savedConfigIds") ?? []
        return savedIds.compactMap { UUID(uuidString: $0) }.compactMap { loadConfiguration(withId: $0) }
    }
    
    /// Deletes a configuration from UserDefaults using its UUID.
    /// - Parameter id: The UUID of the Configuration to delete.
    static func deleteConfiguration(withId id: UUID) {
        // Remove the configuration data.
        UserDefaults.standard.removeObject(forKey: "savedConfig_\(id.uuidString)")
        
        // Update the list of saved configuration IDs.
        var savedIds = UserDefaults.standard.stringArray(forKey: "savedConfigIds") ?? []
        savedIds.removeAll { $0 == id.uuidString }
        UserDefaults.standard.set(savedIds, forKey: "savedConfigIds")
    }
}
