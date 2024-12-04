import SwiftUI

struct TradesmenDetailView: View {
    var tradesman: Tradesmen?

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                if let tradesman = tradesman {
                    // Profile Section
                    VStack(spacing: 16) {
                        Circle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(tradesman.name?.prefix(1) ?? "?"))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        Text(tradesman.name ?? "Unknown Tradesman")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Points: \(tradesman.points)")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(20)
                    .shadow(radius: 5)

                    // Badges Section
                    VStack(spacing: 16) {
                        Text("Badges")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        if let badges = tradesman.badges, !badges.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(badges, id: \.self) { badge in
                                        VStack {
                                            Image(systemName: "star.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 50, height: 50)
                                                .foregroundColor(.yellow)
                                            
                                            Text(badge)
                                                .font(.caption)
                                                .multilineTextAlignment(.center)
                                                .padding(.top, 4)
                                        }
                                        .padding()
                                        .background(Color(UIColor.systemGray6))
                                        .cornerRadius(12)
                                        .shadow(radius: 3)
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
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 5)

                    // Actions Section
                    VStack(spacing: 16) {
                        NavigationLink(destination: BadgesView(tradesmanName: tradesman.name ?? "Tradesman")) {
                            HStack {
                                Image(systemName: "rosette")
                                Text("View All Badges")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(10)
                        }

                        NavigationLink(destination: LeaderboardView()) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                Text("View Leaderboard")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    // Placeholder for no tradesmen
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
                    .padding()
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle(tradesman?.name ?? "Tradesman")
        .navigationBarTitleDisplayMode(.inline)
    }
}
