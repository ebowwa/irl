//
//  ImageGenLogsDisplay.swift
//  irl
//
//  Created by Elijah Arbee on 9/25/24.
//
import SwiftUI

struct ImageGenLogsDisplay: View {
    let generationLogs: String?

    var body: some View {
        if let logs = generationLogs, !logs.isEmpty {
            VStack(alignment: .leading) {
                Text("Generation Logs:").font(.headline)
                ScrollView {
                    Text(logs)
                        .font(.caption)
                        .padding()
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                }.frame(height: 150)

                Button(action: {
                    UIPasteboard.general.string = logs
                }) {
                    Text("Copy Logs")
                        .font(.caption)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
}
