//
//  DashboardCardComponents.swift
//  irl
//
//  Created on 8/30/24.
//

import SwiftUI

struct CardView: View {
    let title: String
    let description: String
    let buttonText: String
    let buttonAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("PrimaryTextColor"))
            Text(description)
                .font(.subheadline)
                .foregroundColor(Color("SecondaryTextColor"))
                .lineLimit(3)
            Button(action: buttonAction) {
                Text(buttonText)
                    .font(.callout)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("AccentColor"))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color("CardBackgroundColor"))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ChartCardView: View {
    let title: String
    let data: [Double]

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)

            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height

                    path.move(to: CGPoint(x: 0, y: height * (1 - CGFloat(data[0]))))

                    for (index, point) in data.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = height * (1 - CGFloat(point))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color("AccentColor"), lineWidth: 2)
            }
        }
        .padding()
        .background(Color("CardBackgroundColor"))
        .cornerRadius(12)
    }
}

struct RecentActivityCardView: View {
    let activities: [String]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)

            List {
                ForEach(activities, id: \.self) { activity in
                    HStack {
                        Circle()
                            .fill(Color("AccentColor"))
                            .frame(width: 10, height: 10)
                        Text(activity)
                            .font(.subheadline)
                    }
                }
            }
            .frame(height: 200)
        }
        .background(Color("CardBackgroundColor"))
        .cornerRadius(12)
    }
}
