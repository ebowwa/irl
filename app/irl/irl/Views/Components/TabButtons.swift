//
//  TabButtons.swift
//  IRL
//
//  Created by Elijah Arbee on 10/25/24.
//

import SwiftUI
import Foundation

// MARK: - TabItem Struct
struct TabItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let selectedIcon: String
    let content: () -> AnyView
    let showButtons: Bool // Indicates if buttons should be shown for this tab
}

// File 2: TabButton.swift

import SwiftUI

// MARK: - TabButton View
struct TabButton: View {
    let title: String
    let icon: String
    let selectedIcon: String
    let isSelected: Bool
    let gradient: LinearGradient
    let inactiveColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.caption)
                    .bold()
            }
            .frame(maxWidth: .infinity, maxHeight: 40)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? gradient
                    : LinearGradient(
                        gradient: Gradient(colors: [inactiveColor, inactiveColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                      )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: isSelected ? Color.black.opacity(0.2) : .clear, radius: 4, x: 0, y: 4)
        }
    }
}

