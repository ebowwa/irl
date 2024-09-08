//
//  AudioRecordingModel.swift
//  irl
//
//  Created by Elijah Arbee on 9/7/24.
//

import Foundation
// MARK: - Models
struct AudioRecording: Identifiable {
    let id: UUID
    let url: URL
    let creationDate: Date
    let fileSize: Int64
    var isSpeechLikely: Bool? // want more data than bool ideally how long for convos, %, etc
    var duration: TimeInterval?
}

