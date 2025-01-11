import SwiftUI

struct ConfettiView: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<50, id: \.self) { index in
                ConfettiShape()
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .foregroundColor(randomColor())
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .animation(
                        Animation.easeOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
        }
    }

    private func randomColor() -> Color {
        Color(hue: .random(in: 0...1), saturation: 0.7, brightness: 0.9)
    }
}

struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(CGRect(x: 0, y: 0, width: 5, height: 5))
        return path
    }
}
