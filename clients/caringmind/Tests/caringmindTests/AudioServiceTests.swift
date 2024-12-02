import AVFoundation
@testable import caringmind
import Combine
import XCTest

final class AudioServiceTests: XCTestCase {
    var audioService: AudioService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        audioService = AudioService()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        audioService = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertEqual(audioService.uploadStatus, "Idle")
        XCTAssertFalse(audioService.isRecording)
        XCTAssertTrue(audioService.liveTranscriptions.isEmpty)
        XCTAssertTrue(audioService.historicalTranscriptions.isEmpty)
    }

    func testAudioResultDecoding() throws {
        // Test JSON decoding of AudioResult
        let json = """
        {
            "file": "test.m4a",
            "status": "completed",
            "data": {"text": "Hello world"},
            "file_uri": "https://example.com/test.m4a",
            "stored": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let result = try decoder.decode(AudioResult.self, from: json)

        XCTAssertNotNil(result.id)
        XCTAssertEqual(result.file, "test.m4a")
        XCTAssertEqual(result.status, "completed")
        XCTAssertEqual(result.file_uri, "https://example.com/test.m4a")
        XCTAssertTrue(result.stored)
    }

    func testAnyCodableEncoding() throws {
        // Test encoding of AnyCodable with different types
        let testData: [String: AnyCodable] = [
            "string": AnyCodable("test"),
            "int": AnyCodable(42),
            "double": AnyCodable(3.14),
            "bool": AnyCodable(true),
            "array": AnyCodable(["a", "b", "c"]),
            "dict": AnyCodable(["key": "value"])
        ]

        let encoder = JSONEncoder()
        let encoded = try encoder.encode(testData)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([String: AnyCodable].self, from: encoded)

        XCTAssertEqual(decoded["string"]?.value as? String, "test")
        XCTAssertEqual(decoded["int"]?.value as? Int, 42)
        XCTAssertEqual(decoded["bool"]?.value as? Bool, true)
    }

    func testMaxTranscriptionLimits() {
        // Test live transcription limit
        for i in 0...60 {
            let jsonData = """
            {
                "file": "test\(i).m4a",
                "status": "completed",
                "data": {},
                "file_uri": "https://example.com/test\(i).m4a",
                "stored": true
            }
            """.data(using: .utf8)!

            if let result = try? JSONDecoder().decode(AudioResult.self, from: jsonData) {
                audioService.liveTranscriptions.append(result)
            }
        }

        XCTAssertLessThanOrEqual(audioService.liveTranscriptions.count, 50)
    }

    func testProcessAudioResponseDecoding() throws {
        let json = """
        {
            "results": [
                {
                    "file": "test1.m4a",
                    "status": "completed",
                    "data": {"text": "Hello"},
                    "file_uri": "https://example.com/test1.m4a",
                    "stored": true
                },
                {
                    "file": "test2.m4a",
                    "status": "processing",
                    "data": {},
                    "file_uri": "https://example.com/test2.m4a",
                    "stored": false
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ProcessAudioResponse.self, from: json)
        XCTAssertEqual(response.results?.count, 2)
        XCTAssertEqual(response.results?[0].file, "test1.m4a")
        XCTAssertEqual(response.results?[1].status, "processing")
    }
}
