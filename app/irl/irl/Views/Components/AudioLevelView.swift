//
//  AudioLevelView.swift
//  IRL
//
//  Created by Elijah Arbee on 10/11/24.
//
import SwiftUI

struct AudioLevelView: View {
    @Binding var audioLevel: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("Audio Level")
                .font(.headline)
            ProgressView(value: audioLevel, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 10)
        }
        .padding()
    }
}
