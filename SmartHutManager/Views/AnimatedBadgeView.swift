import SwiftUI

struct AnimatedBadgeView: View {
    let title: String

    @State private var scale: CGFloat = 1.0
    @State private var isHolding: Bool = false
    @State private var elapsedTime: Double = 0.0
    @State private var hasPopped: Bool = false
    @State private var particles: [Particle] = [] // Track particles
    private let maxScale: CGFloat = 2.0 // Maximum scale size
    private let animationTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            if !hasPopped {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 4)
                    .scaleEffect(scale) // Apply scaling

                VStack {
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.yellow)

                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                }
            } else {
                // Pop Effect: Animated Particles
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .offset(x: particle.xOffset, y: particle.yOffset)
                        .opacity(particle.opacity)
                        .animation(
                            Animation.easeOut(duration: particle.lifetime)
                                .delay(Double(particle.id) * 0.05), // Stagger particle animations
                            value: hasPopped
                        )
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding {
                        isHolding = true
                    }
                }
                .onEnded { _ in
                    isHolding = false
                }
        )
        .onReceive(animationTimer) { _ in
            handleAnimationTimer()
        }
        .onAppear {
            particles = generateParticles() // Prepare particles for pop
        }
        .animation(.easeOut(duration: 0.3), value: hasPopped) // Smooth pop animation
    }

    // MARK: - Handle Animation Timer
    private func handleAnimationTimer() {
        guard isHolding else {
            // Deflate when not holding
            if scale > 1.0 {
                let deflationSpeed: CGFloat = 0.015 // Smooth and slower deflation
                scale = max(1.0, scale - deflationSpeed)
                elapsedTime = max(0.0, elapsedTime - 0.02)
            }
            return
        }

        // Inflate while holding
        if scale < maxScale && !hasPopped {
            let inflationSpeed: CGFloat = 0.01 // Slower inflation
            scale += inflationSpeed
        }

        // Pop as soon as it reaches maxScale
        if scale >= maxScale && !hasPopped {
            pop()
        }
    }

    // MARK: - Pop Action
    private func pop() {
        hasPopped = true // Trigger pop effect
        vibrate() // Trigger vibration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resetBadge() // Reset badge after pop effect
        }
    }

    private func resetBadge() {
        hasPopped = false
        scale = 1.0
        elapsedTime = 0.0
    }

    // MARK: - Vibration on Pop
    private func vibrate() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    // MARK: - Particle Generation
    private func generateParticles() -> [Particle] {
        (0..<10).map { index in
            Particle(
                id: index,
                size: CGFloat.random(in: 5...10),
                xOffset: CGFloat.random(in: -50...50),
                yOffset: CGFloat.random(in: -50...50),
                color: [Color.yellow, Color.orange, Color.red].randomElement() ?? .yellow,
                opacity: Double.random(in: 0.7...1.0),
                lifetime: Double.random(in: 0.5...1.0)
            )
        }
    }
}

// MARK: - Particle Model
struct Particle: Identifiable {
    let id: Int
    let size: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat
    let color: Color
    let opacity: Double
    let lifetime: Double
}
