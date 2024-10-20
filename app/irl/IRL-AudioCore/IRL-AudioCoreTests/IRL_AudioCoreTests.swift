//
//  IRL_AudioCoreTests.swift
//  IRL-AudioCoreTests
//
//  Created by Elijah Arbee on 10/20/24.
/**
import XCTest
import Testing
@testable import IRL_AudioCore

class AudioFrameworkTests: XCTestCase {

    func testAudioStateInitialization() {
        // Verify that the shared instance is not nil
        XCTAssertNotNil(AudioState.shared)
        
        // Verify initial properties
        XCTAssertFalse(AudioState.shared.isRecording)
        XCTAssertFalse(AudioState.shared.isPlaying)
        XCTAssertEqual(AudioState.shared.recordingTime, 0)
    }

    func testStartAndStopRecording() {
        let audioState = AudioState.shared

        // Start recording
        audioState.startRecording()

        // Assert that recording has started
        XCTAssertTrue(audioState.isRecording)

        // Stop recording
        audioState.stopRecording()

        // Assert that recording has stopped
        XCTAssertFalse(audioState.isRecording)
    }
}
*/
