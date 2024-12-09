import SwiftUI

struct CircuitBackground: View {
    let circuitPhase: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let gridSize: CGFloat = 30
                
                for x in stride(from: 0, to: geometry.size.width, by: gridSize) {
                    for y in stride(from: 0, to: geometry.size.height, by: gridSize) {
                        if Bool.random() {
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x + gridSize, y: y))
                        }
                        if Bool.random() {
                            path.move(to: CGPoint(x: x, y: y))
                            path.addLine(to: CGPoint(x: x, y: y + gridSize))
                        }
                    }
                }
            }
            .stroke(Color.green.opacity(0.1), style: StrokeStyle(
                lineWidth: 1,
                lineCap: .round,
                lineJoin: .round,
                dashPhase: circuitPhase
            ))
        }
    }
}

#Preview {
    CircuitBackground(circuitPhase: 0)
        .preferredColorScheme(.dark)
}
