//
//  KeyEntity+CoreDataClass.swift
//  irl
//
//  Created by Elijah Arbee on 9/19/24.
//
// KeyEntity+CoreDataClass.swift
import Foundation
import CoreData

@objc(KeyEntity)
public class KeyEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeyEntity> {
        return NSFetchRequest<KeyEntity>(entityName: "KeyEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var embedding: Data?
    @NSManaged public var relationships: Set<RelationshipEntity>
}

// RelationshipEntity+CoreDataClass.swift
import Foundation
import CoreData

@objc(RelationshipEntity)
public class RelationshipEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RelationshipEntity> {
        return NSFetchRequest<RelationshipEntity>(entityName: "RelationshipEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var embedding: Data?
    @NSManaged public var source: KeyEntity
    @NSManaged public var target: KeyEntity
}
