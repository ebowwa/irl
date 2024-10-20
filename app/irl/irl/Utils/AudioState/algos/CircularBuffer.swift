//
//  CircularBuffer.swift
//  IRL
//
//  Created by Elijah Arbee on 10/15/24.
//


//
//  CircularBuffer.swift
//  irl
//
//  Created by Elijah Arbee on 10/15/24.
//

import Foundation

/// A generic circular buffer (ring buffer) implementation.
/// - Note: Thread-safe operations using `NSLock`.
public class CircularBuffer<T> {
    private var buffer: [T?]
    private var head: Int = 0
    private var tail: Int = 0
    private let capacity: Int
    private let lock = NSLock()
    
    /// Initializes the circular buffer with a specified capacity.
    /// - Parameter capacity: The maximum number of elements the buffer can hold.
    public init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }
    
    /// Adds an element to the buffer. Overwrites the oldest data if the buffer is full.
    /// - Parameter element: The element to be added.
    public func enqueue(_ element: T) {
        lock.lock()
        buffer[head] = element
        head = (head + 1) % capacity
        if head == tail {
            // Buffer is full, overwrite the oldest data
            tail = (tail + 1) % capacity
        }
        lock.unlock()
    }
    
    /// Removes and returns the oldest element from the buffer.
    /// - Returns: The oldest element if available; otherwise, `nil`.
    public func dequeue() -> T? {
        lock.lock()
        guard tail != head, let element = buffer[tail] else {
            lock.unlock()
            return nil
        }
        buffer[tail] = nil
        tail = (tail + 1) % capacity
        lock.unlock()
        return element
    }
    
    /// Clears all elements from the buffer.
    public func clear() {
        lock.lock()
        buffer = Array(repeating: nil, count: capacity)
        head = 0
        tail = 0
        lock.unlock()
    }
    
    /// Indicates whether the buffer is empty.
    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return tail == head
    }
    
    /// Indicates whether the buffer is full.
    public var isFull: Bool {
        lock.lock()
        defer { lock.unlock() }
        return (head + 1) % capacity == tail
    }
}
