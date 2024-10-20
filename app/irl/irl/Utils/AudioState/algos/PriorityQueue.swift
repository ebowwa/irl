//
//  PriorityQueue.swift
//  IRL
//
//  Created by Elijah Arbee on 10/15/24.
//


//
//  PriorityQueue.swift
//  irl
//
//  Created by Elijah Arbee on 10/15/24.
//

import Foundation

/// A generic priority queue implementation using a heap.
/// - Note: Higher priority elements are dequeued first.
public struct PriorityQueue<Element> {
    private var heap: [Element] = []
    private let areInIncreasingOrder: (Element, Element) -> Bool
    
    /// Initializes the priority queue with a sorting closure.
    /// - Parameter sort: A closure that defines the priority order.
    public init(sort: @escaping (Element, Element) -> Bool) {
        self.areInIncreasingOrder = sort
    }
    
    /// Indicates whether the priority queue is empty.
    public var isEmpty: Bool {
        return heap.isEmpty
    }
    
    /// The number of elements in the priority queue.
    public var count: Int {
        return heap.count
    }
    
    /// Adds an element to the priority queue.
    /// - Parameter element: The element to be added.
    public mutating func enqueue(_ element: Element) {
        heap.append(element)
        siftUp(from: heap.count - 1)
    }
    
    /// Removes and returns the highest priority element from the queue.
    /// - Returns: The highest priority element if available; otherwise, `nil`.
    public mutating func dequeue() -> Element? {
        guard !heap.isEmpty else { return nil }
        if heap.count == 1 {
            return heap.removeFirst()
        } else {
            let first = heap.first
            heap[0] = heap.removeLast()
            siftDown(from: 0)
            return first
        }
    }
    
    /// Sifts up the element at the specified index to maintain heap property.
    private mutating func siftUp(from index: Int) {
        var child = index
        var parent = self.parent(of: child)
        while child > 0 && areInIncreasingOrder(heap[child], heap[parent]) {
            heap.swapAt(child, parent)
            child = parent
            parent = self.parent(of: child)
        }
    }
    
    /// Sifts down the element at the specified index to maintain heap property.
    private mutating func siftDown(from index: Int) {
        var parent = index
        while true {
            let left = self.leftChild(of: parent)
            let right = left + 1
            var candidate = parent
            if left < heap.count && areInIncreasingOrder(heap[left], heap[candidate]) {
                candidate = left
            }
            if right < heap.count && areInIncreasingOrder(heap[right], heap[candidate]) {
                candidate = right
            }
            if candidate == parent {
                return
            }
            heap.swapAt(parent, candidate)
            parent = candidate
        }
    }
    
    /// Returns the parent index of the specified child index.
    private func parent(of index: Int) -> Int {
        return (index - 1) / 2
    }
    
    /// Returns the left child index of the specified parent index.
    private func leftChild(of index: Int) -> Int {
        return 2 * index + 1
    }
}
