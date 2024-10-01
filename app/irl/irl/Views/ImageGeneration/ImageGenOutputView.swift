//
//  ImageGenOutputView.swift
//  irl
//
//  Created by Elijah Arbee on 9/25/24.
//
import SwiftUI

struct ImageGenOutputView: View {
    let imageUrlString: String?

    var body: some View {
        if let urlString = imageUrlString, let url = URL(string: urlString) {
            Text("Generated Image:").font(.headline)
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit).cornerRadius(8)
                case .failure:
                    FailedImagePlaceholder()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 300)
            .shadow(radius: 5)
        }
    }
}

struct FailedImagePlaceholder: View {
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.red)
            Text("Failed to load image.")
                .foregroundColor(.red)
                .font(.caption)
        }
    }
}
