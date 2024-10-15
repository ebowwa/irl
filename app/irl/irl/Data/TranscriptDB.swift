//
//  TranscriptDB.swift
//  IRL
//
//  Created by Elijah Arbee on 10/12/24.
//
import Foundation
import SQLite
import Combine
// TODO: add timestamps and optional additions for diarizartion and other variables later
class TranscriptDB {
    static let shared = TranscriptDB()
    
    private let db: Connection?
    private let transcriptions = Table("transcriptions")
    private let id = SQLite.Expression<Int64>("id")
    private let textColumn = SQLite.Expression<String>("text")
    
    // Publisher to notify subscribers about new transcriptions
    let transcriptionSubject = PassthroughSubject<String, Never>()
    
    private init() {
        // Get the file path to store the database
        if let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first {
            do {
                db = try Connection("\(path)/transcriptions.sqlite3")
                createTable()
            } catch {
                db = nil
                print("Unable to open database. Error: \(error)")
            }
        } else {
            db = nil
            print("Unable to find documents directory.")
        }
    }
    
    func createTable() {
        do {
            try db?.run(transcriptions.create(ifNotExists: true) { table in
                table.column(id, primaryKey: true)
                table.column(textColumn)
            })
        } catch {
            print("Unable to create table. Error: \(error)")
        }
    }
    
    func insertTranscription(_ transcriptionText: String) {
        do {
            let insert = transcriptions.insert(textColumn <- transcriptionText)
            try db?.run(insert)
            // Publish the new transcription on the main thread
            DispatchQueue.main.async {
                self.transcriptionSubject.send(transcriptionText)
            }
        } catch {
            print("Unable to insert transcription. Error: \(error)")
        }
    }

    
    func getAllTranscriptions() -> [String] {
        var result: [String] = []
        do {
            for transcription in try db!.prepare(transcriptions) {
                result.append(transcription[textColumn])
            }
        } catch {
            print("Unable to retrieve transcriptions. Error: \(error)")
        }
        return result
    }
}
