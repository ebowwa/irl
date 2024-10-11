//
//  RecordingIndicatorView.swift
//  IRL
//
//  Created by Elijah Arbee on 10/10/24.
//


// Views/RecordingIndicatorView.swift

import SwiftUI

struct RecordingIndicatorView: View {
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12) // Red dot indicating recording
                Text("Recording...")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .padding(8)
            .background(Color.black.opacity(0.6))
            .cornerRadius(8)
            .padding(.top, 20) // Adjust placement if necessary
            Spacer()
        }
    }
}
