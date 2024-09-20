//
//  FloatArrayTransformer.swift
//  irl
//
//  Created by Elijah Arbee on 9/19/24.
//
// FloatArrayTransformer.swift
import Foundation
import CoreData

@objc(FloatArrayTransformer)
class FloatArrayTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }

    override class func allowsReverseTransformation() -> Bool {
        return true
    }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let floatArray = value as? [Float] else { return nil }
        return try? JSONEncoder().encode(floatArray)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode([Float].self, from: data)
    }
}
// EmbeddingTransformable.swift
import Foundation

extension KeyEntity {
    var floatEmbedding: [Float] {
        get {
            guard let data = embedding else { return [] }
            return (try? JSONDecoder().decode([Float].self, from: data)) ?? []
        }
        set {
            embedding = (try? JSONEncoder().encode(newValue))
        }
    }
}

extension RelationshipEntity {
    var floatEmbedding: [Float] {
        get {
            guard let data = embedding else { return [] }
            return (try? JSONDecoder().decode([Float].self, from: data)) ?? []
        }
        set {
            embedding = (try? JSONEncoder().encode(newValue))
        }
    }
}
