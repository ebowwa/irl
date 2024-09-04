//
//  SystemModels.swift
//  irl
//
//  Created by Elijah Arbee on 8/29/24.
//
import Foundation

struct User: Identifiable {
    let id: UUID
    let name: String
    let email: String
}

struct Notification: Identifiable {
    let id: UUID
    let title: String
    let body: String
}

enum Theme: String {
    case light, dark
}

enum Language: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case defaut = "auto-detect" // default displayed
}
