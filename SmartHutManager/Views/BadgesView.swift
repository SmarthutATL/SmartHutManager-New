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
                            AnimatedBadgeView(title: badge) // Use the animated badge view
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
