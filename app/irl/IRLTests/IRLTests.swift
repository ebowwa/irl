//
//  IRLTests.swift
//  IRLTests
//
//  Created by Elijah Arbee on 10/8/24.
//


import XCTest
@testable import IRL

final class IRLTests: XCTestCase {

    
    
    // MARK: - AudioState Module Tests
    // Test to ensure recording starts and stops correctly
        func testAlwaysRecording() throws {
            // Start the first recording
            AudioState.shared.startRecording()
            print("Recording started: \(AudioState.shared.isRecording)")

            // Ensure recording started
            XCTAssertTrue(AudioState.shared.isRecording, "Recording should have started")

            // Stop the recording
            AudioState.shared.stopRecording()
            print("Recording stopped: \(AudioState.shared.isRecording)")

            // Ensure recording stopped
            XCTAssertFalse(AudioState.shared.isRecording, "Recording should have stopped")

            // Start the recording again
            AudioState.shared.startRecording()
            print("Recording restarted: \(AudioState.shared.isRecording)")
            XCTAssertTrue(AudioState.shared.isRecording, "Recording should have restarted")
        }

    // Test to check that the system continuously records without delay
    func testContinuousRecording() throws {
        // Start the first recording
        AudioState.shared.startRecording()
        XCTAssertTrue(AudioState.shared.isRecording, "Recording should have started")

        // Simulate recording for a short time and then stop
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            AudioState.shared.stopRecording()
        }

        // After stopping, check if a new recording starts
        DispatchQueue.global().asyncAfter(deadline: .now() + 6) {
            XCTAssertTrue(AudioState.shared.isRecording, "Recording should resume immediately after stopping")
        }
    }

    // Test to ensure the recording timer resets between sessions
    func testRecordingTimerReset() throws {
        // Start recording
        AudioState.shared.startRecording()

        // Ensure timer starts at 0
        XCTAssertEqual(AudioState.shared.recordingTime, 0, "Recording timer should start at 0")
        
        // Let the recording run for 5 seconds, then stop
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            AudioState.shared.stopRecording()
        }

        // Ensure timer resets on a new recording
        DispatchQueue.global().asyncAfter(deadline: .now() + 6) {
            AudioState.shared.startRecording()
            XCTAssertEqual(AudioState.shared.recordingTime, 0, "Recording timer should reset after a new recording starts")
        }

        // Ensure timer is counting again after recording starts
        DispatchQueue.global().asyncAfter(deadline: .now() + 8) {
            XCTAssertGreaterThan(AudioState.shared.recordingTime, 0, "Recording timer should start counting again")
        }
    }

    // Test to handle errors during recording and ensure recording resumes correctly
    func testErrorHandlingInRecording() throws {
        // Simulate a failed recording start due to some error
        AudioState.shared.startRecording()

        // Simulate an error during the process
        AudioState.shared.errorMessage = "Failed to start audio engine"

        // Ensure error message is logged
        XCTAssertNotNil(AudioState.shared.errorMessage, "Error message should be set")
        
        // Ensure that recording can still start after the error
        AudioState.shared.startRecording()
        XCTAssertTrue(AudioState.shared.isRecording, "Recording should still be able to start after an error")
    }

    // Test to switch between file-based recording and live streaming, ensuring continuous recording
    func testSwitchingBetweenRecordingModes() throws {
        // Start file-based recording
        AudioState.shared.startFileRecording()
        XCTAssertTrue(AudioState.shared.isRecording, "File-based recording should have started")

        // Simulate switching to live streaming after a few seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            AudioState.shared.stopRecording() // Stop file recording
            AudioState.shared.startLiveStreaming() // Start live streaming recording
        }

        // Ensure live streaming recording starts successfully
        DispatchQueue.global().asyncAfter(deadline: .now() + 6) {
            XCTAssertTrue(AudioState.shared.isRecording, "Live streaming should start after switching")
        }

        // Switch back to file recording
        DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
            AudioState.shared.stopRecording() // Stop live streaming
            AudioState.shared.startFileRecording() // Start file recording again
        }

        // Ensure file recording resumes after switching back
        DispatchQueue.global().asyncAfter(deadline: .now() + 12) {
            XCTAssertTrue(AudioState.shared.isRecording, "File recording should restart after switching back")
        }
    }
}
