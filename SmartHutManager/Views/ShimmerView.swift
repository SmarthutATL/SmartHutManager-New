import SwiftUI

struct ShimmerView: View {
    @State private var shimmerPosition: CGFloat = -1

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.4), Color.clear, Color.white.opacity(0.4)]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .blur(radius: 10)
            .offset(x: geometry.size.width * shimmerPosition)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 2)
                        .repeatForever(autoreverses: false)
                ) {
                    shimmerPosition = 2
                }
            }
        }
    }
}
