//
//  SlidingWindow.swift
//  IRL
//
//  Created by Elijah Arbee on 10/15/24.
//


//
//  SlidingWindow.swift
//  irl
//
//  Created by Elijah Arbee on 10/15/24.
//

import Foundation

/// A generic sliding window implementation for aggregating data over a moving window.
public class SlidingWindow<T> {
    private var window: [T] = []
    private let maxSize: Int
    private let lock = NSLock()
    
    /// Initializes the sliding window with a maximum size.
    /// - Parameter maxSize: The maximum number of elements the window can hold.
    public init(maxSize: Int) {
        self.maxSize = maxSize
    }
    
    /// Adds an element to the sliding window. Removes the oldest element if the window is full.
    /// - Parameter element: The element to be added.
    public func add(_ element: T) {
        lock.lock()
        window.append(element)
        if window.count > maxSize {
            window.removeFirst()
        }
        lock.unlock()
    }
    
    /// Retrieves the current elements in the sliding window.
    /// - Returns: An array of elements currently in the window.
    public func getWindow() -> [T] {
        lock.lock()
        let currentWindow = window
        lock.unlock()
        return currentWindow
    }
}
