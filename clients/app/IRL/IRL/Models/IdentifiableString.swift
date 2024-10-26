// Models/IdentifiableString.swift

import Foundation

/// A wrapper struct to make String identifiable.
struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}
