//
//  AudioTask.swift
//  IRL
//
//  Created by Elijah Arbee on 10/15/24.
//


//
//  AudioTask.swift
//  irl
//
//  Created by Elijah Arbee on 10/15/24.
//

import Foundation

/// Represents an audio processing task with an associated priority.
public struct AudioTask {
    /// Defines the priority levels for audio tasks.
    public enum Priority: Int, Comparable {
        case high = 3
        case medium = 2
        case low = 1
        
        /// Implements the `<` operator to conform to `Comparable`.
        public static func < (lhs: AudioTask.Priority, rhs: AudioTask.Priority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
    
    /// The priority of the task.
    public let priority: Priority
    
    /// The closure to be executed when the task is processed.
    public let execute: () -> Void
    
    /// Initializes an audio task with a specified priority and execution closure.
    /// - Parameters:
    ///   - priority: The priority level of the task.
    ///   - execute: The closure to execute.
    public init(priority: Priority, execute: @escaping () -> Void) {
        self.priority = priority
        self.execute = execute
    }
}
