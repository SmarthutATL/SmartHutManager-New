import SwiftUI

struct TradesmenDetailView: View {
    var tradesman: Tradesmen?
    @State private var badgesShineOffset: CGFloat = -250
    @State private var leaderboardShineOffset: CGFloat = 250

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                if let tradesman = tradesman {
                    // Profile Section
                    profileSection(tradesman: tradesman)
                        .padding(.horizontal)

                    // Points Section
                    pointsSection(tradesman: tradesman)
                        .padding(.horizontal)

                    // Badges Section
                    badgesSection(tradesman: tradesman)
                        .padding(.horizontal)

                    // Actions Section
                    actionsSection(tradesman: tradesman)
                        .padding(.horizontal)
                } else {
                    noTradesmanPlaceholder()
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .onAppear {
                startShineAnimation() // Start the shine animation when the view appears
            }
        }
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all)) // Background adapts to dark or light mode
        .navigationTitle("Technician Leaderboards")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Profile Section
    private func profileSection(tradesman: Tradesmen) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .pink, .blue]),
                            center: .center
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text(String(tradesman.name?.prefix(1) ?? "?"))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }

            Text(tradesman.name ?? "Unknown Tradesman")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialLight)
                .cornerRadius(20)
        )
        .shadow(radius: 10)
    }

    // MARK: - Points Section
    private func pointsSection(tradesman: Tradesmen) -> some View {
        VStack {
            Text("Points")
                .font(.headline)
                .foregroundColor(.primary)

            Text("\(tradesman.points)")
                .font(.title.bold())
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    private func badgesSection(tradesman: Tradesmen) -> some View {
        VStack(spacing: 16) {
            Text("Badges")
                .font(.headline)
                .foregroundColor(.blue)

            // Safely convert badges to a Swift array
            if let badges = tradesman.badges as? [String], !badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(badges, id: \.self) { badge in
                            BadgeView(badge: badge)
                                .frame(width: 120, height: 150)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 180)
            } else {
                Text("No badges yet")
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
    }
    // MARK: - Actions Section
    private func actionsSection(tradesman: Tradesmen) -> some View {
        VStack(spacing: 16) {
            shiningButton(
                title: "View All Badges",
                icon: "rosette",
                gradientColors: [Color.purple, Color.blue],
                destination: AnyView(BadgesView(tradesmanName: tradesman.name ?? "Tradesman")),
                shineOffset: $badgesShineOffset
            )

            shiningButton(
                title: "View Leaderboard",
                icon: "chart.bar.fill",
                gradientColors: [Color.purple, Color.blue],
                destination: AnyView(LeaderboardView()),
                shineOffset: $leaderboardShineOffset
            )
        }
    }

    // MARK: - Shining Button Helper
    private func shiningButton(
        title: String,
        icon: String,
        gradientColors: [Color],
        destination: AnyView,
        shineOffset: Binding<CGFloat>
    ) -> some View {
        NavigationLink(destination: destination) {
            ZStack {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
                .shadow(radius: 5)

                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 400, height: 60)
                    .offset(x: shineOffset.wrappedValue)
                    .mask(
                        HStack {
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(.white)
                            Text(title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                    )
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - No Tradesman Placeholder
    private func noTradesmanPlaceholder() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.questionmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.gray)

            Text("No Tradesman Available")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.gray)
        }
    }

    // MARK: - Continuous Shine Animation
    private func startShineAnimation() {
        withAnimation(
            Animation.linear(duration: 4.0)
                .repeatForever(autoreverses: true)
        ) {
            badgesShineOffset = 150
        }

        withAnimation(
            Animation.linear(duration: 4.0)
                .repeatForever(autoreverses: true)
        ) {
            leaderboardShineOffset = -150
        }
    }
}

struct CustomButton: View {
    var title: String
    var icon: String
    var gradientColors: [Color]
    var destination: AnyView
    
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
            .shadow(radius: 5)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}

struct BadgeView: View {
    var badge: String
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.yellow)
            
            Text(badge)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 80)
                .foregroundColor(.white)
        }
        .frame(width: 120, height: 120)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.6), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .shadow(radius: 5)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring()) {
                isPressed.toggle()
            }
        }
    }
}


// MARK: - Visual Effect Blur for Frosted Background
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}
