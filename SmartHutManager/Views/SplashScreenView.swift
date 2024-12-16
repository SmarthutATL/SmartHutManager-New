import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var shineOffset: CGFloat = -250

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea() // White background
            
            VStack {
                Spacer()
                
                ZStack {
                    // Logo Image with Scale and Opacity Animation
                    Image("smarthut_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .onAppear {
                            withAnimation(.spring(response: 1.2, dampingFraction: 0.6, blendDuration: 0.5)) {
                                logoScale = 1.0
                                logoOpacity = 1.0
                            }
                        }
                    
                    // Shining Animation
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .white.opacity(0.8), .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(30)) // Tilt the shine effect
                        .offset(x: shineOffset)
                        .mask(
                            Image("smarthut_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                        )
                        .onAppear {
                            startContinuousShine()
                        }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Continuous Shining Animation
    private func startContinuousShine() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            shineOffset = 250 // Moves the shine effect across the logo
        }
    }
}
