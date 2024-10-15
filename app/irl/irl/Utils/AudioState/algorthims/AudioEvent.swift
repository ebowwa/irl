//
//  AudioEvent.swift
//  IRL
//
//  Created by Elijah Arbee on 10/15/24.
//


//
//  EventBus.swift
//  irl
//
//  Created by Elijah Arbee on 10/15/24.
//

import Foundation
import Combine

/// Defines the various audio-related events that can be published and subscribed to.
public enum AudioEvent {
    case audioLevelUpdated(Float)
    case recordingStarted
    case recordingStopped
    case playbackStarted
    case playbackStopped
    case errorOccurred(String)
}

/// A singleton class that manages the publishing and subscribing of audio events using Combine.
public class EventBus {
    public static let shared = EventBus()
    private init() {}
    
    private let eventSubject = PassthroughSubject<AudioEvent, Never>()
    
    /// A publisher that external components can subscribe to for receiving audio events.
    public var eventPublisher: AnyPublisher<AudioEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    /// Publishes a new audio event.
    /// - Parameter event: The event to be published.
    public func publish(_ event: AudioEvent) {
        eventSubject.send(event)
    }
}
