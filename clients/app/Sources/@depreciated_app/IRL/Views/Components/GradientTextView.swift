import SwiftUI

struct GradientTextView: View {
    var text: String
    let blueHex = Color(red: 0.0, green: 0.0, blue: 1.0) // Exact blue hue
    let blackHex = Color.black

    var body: some View {
        gradientText(text)
    }

    // Gradient Text Function with the most recent word in blue
    private func gradientText(_ text: String) -> Text {
        let words = text.split(separator: " ")
        let count = words.count
        let gradientFactor = 1.0 / Double(count) // Determines how fast the color shifts

        // Apply the gradient from the start (black) to end (blue)
        return words.enumerated().reduce(Text("")) { (partialResult, pair) -> Text in
            let (index, word) = pair
            let fraction = Double(index) * gradientFactor
            let color = Color.lerp(from: blackHex, to: blueHex, fraction: fraction)
            return partialResult + Text(" \(word)").foregroundColor(color)
        }
    }
}

// Helper for color interpolation (gradient effect)
extension Color {
    static func lerp(from: Color, to: Color, fraction: Double) -> Color {
        let fromComponents = from.cgColor?.components ?? [0, 0, 0, 1]
        let toComponents = to.cgColor?.components ?? [0, 0, 0, 1]

        let red = fromComponents[0] + (toComponents[0] - fromComponents[0]) * fraction
        let green = fromComponents[1] + (toComponents[1] - fromComponents[1]) * fraction
        let blue = fromComponents[2] + (toComponents[2] - fromComponents[2]) * fraction

        return Color(red: red, green: green, blue: blue)
    }
}

