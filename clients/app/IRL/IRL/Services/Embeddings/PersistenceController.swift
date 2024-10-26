//
//  PersistenceController.swift
//  irl
//
//  Created by Elijah Arbee on 9/19/24.
//
// PersistenceController.swift
import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "KnowledgeGraphModel") // Ensure this matches your .xcdatamodeld filename

        // Configure SQLite as the persistent store
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.type = NSSQLiteStoreType

        // Enable automatic lightweight migrations
        storeDescription?.shouldMigrateStoreAutomatically = true
        storeDescription?.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }

        // Optimize for performance
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var context: NSManagedObjectContext {
        return container.viewContext
    }
}
