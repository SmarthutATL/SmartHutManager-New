import SwiftUI

struct TradesmenDetailView: View {
    var tradesman: Tradesmen?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                if let tradesman = tradesman {
                    
                    // Profile Section
                    profileSection(tradesman: tradesman)
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
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
        )
        .navigationTitle("Technician Leaderboards")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Profile Section
    private func profileSection(tradesman: Tradesmen) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .rotationEffect(Angle(degrees: 360))
                    .animation(
                        Animation.linear(duration: 20).repeatForever(autoreverses: false),
                        value: tradesman.name
                    )
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
            
            Text("Points: \(tradesman.points)")
                .font(.headline)
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            VisualEffectBlur(blurStyle: .systemMaterialLight)
                .cornerRadius(20)
        )
        .shadow(radius: 10)
    }
    
    // Badges Section
    private func badgesSection(tradesman: Tradesmen) -> some View {
        VStack(spacing: 16) {
            Text("Badges")
                .font(.headline)
                .foregroundColor(.blue)
            
            if let badges = tradesman.badges, !badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(badges, id: \.self) { badge in
                            BadgeView(badge: badge)
                        }
                    }
                    .padding(.horizontal)
                }
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
            CustomButton(
                title: "View All Badges",
                icon: "rosette",
                gradientColors: [Color.blue, Color.purple],
                destination: AnyView(BadgesView(tradesmanName: tradesman.name ?? "Tradesman"))
            )
            
            CustomButton(
                title: "View Leaderboard",
                icon: "chart.bar.fill",
                gradientColors: [Color.green, Color.blue],
                destination: AnyView(LeaderboardView())
            )
        }
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
