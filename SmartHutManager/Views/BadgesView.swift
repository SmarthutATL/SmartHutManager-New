import SwiftUI

struct BadgesView: View {
    let tradesmanName: String
    @State private var badges: [String] = []
    @Environment(\.managedObjectContext) var context
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Title Section
                VStack(spacing: 4) {
                    Text(tradesmanName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Badges")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
                
                if badges.isEmpty {
                    // Empty State View
                    emptyStateView()
                } else {
                    // Grid Display for Badges
                    LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                        ForEach(badges, id: \.self) { badge in
                            badgeItemView(badge: badge)
                                .transition(.scale)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .onAppear {
                loadBadges(for: tradesmanName)
            }
        }
    }
    
    // MARK: - Empty State View
    private func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "rosette")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.white.opacity(0.7))
            
            Text("No badges available.")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark))
        .cornerRadius(20)
        .shadow(radius: 5)
    }
    
    // MARK: - Badge Item View
    private func badgeItemView(badge: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.yellow)
            
            Text(badge)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
        }
        .frame(width: 120, height: 120)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 5, x: 2, y: 4)
        .scaleEffect(0.95)
        .onTapGesture {
            withAnimation(.spring()) {
                // Add interactivity if needed
            }
        }
    }
    
    // MARK: - Adaptive Grid Layout
    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 120), spacing: 16)]
    }
    
    // MARK: - Load Badges Function
    private func loadBadges(for tradesman: String) {
        withAnimation(.easeInOut(duration: 0.5)) {
            badges = GamificationManager.shared.getBadges(for: tradesman, context: context)
        }
    }
}
