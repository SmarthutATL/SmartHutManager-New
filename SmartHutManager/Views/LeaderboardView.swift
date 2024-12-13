import SwiftUI

struct LeaderboardView: View {
    @Environment(\.managedObjectContext) var context // Access Core Data context
    @State private var leaderboardData: [(user: String, points: Int, image: String)] = [] // Include image for users

    var body: some View {
        VStack {
            // Top 3 Section
            if leaderboardData.count >= 3 {
                HStack(spacing: 16) {
                    Spacer()

                    // 2nd Place (Left)
                    if leaderboardData.count >= 2 {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 70, height: 70)
                                Text(getInitials(for: leaderboardData[1].user))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Text(leaderboardData[1].user)
                                .font(.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("\(leaderboardData[1].points) pts")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    // 1st Place (Center)
                    VStack {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 110, height: 110)
                                .overlay(
                                    ShimmerView()
                                        .frame(width: 110, height: 110)
                                        .clipShape(Circle())
                                )
                            Text(getInitials(for: leaderboardData[0].user))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Text(leaderboardData[0].user)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .fontWeight(.bold)
                        Text("\(leaderboardData[0].points) pts")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }

                    // 3rd Place (Right)
                    if leaderboardData.count >= 3 {
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 70, height: 70)
                                Text(getInitials(for: leaderboardData[2].user))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            Text(leaderboardData[2].user)
                                .font(.subheadline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("\(leaderboardData[2].points) pts")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 20)
            }

            // Tabs for filtering leaderboard (Today, Week, All Time)
            HStack {
                ForEach(["Today", "Week", "All Time"], id: \.self) { filter in
                    Text(filter)
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(.blue)
                        .onTapGesture {
                            // Implement filter logic
                        }
                }
            }
            .padding(.bottom, 16)

            // Full Leaderboard List
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(leaderboardData.enumerated()), id: \.offset) { index, entry in
                        HStack(spacing: 12) {
                            // Rank
                            Text("#\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(width: 40, alignment: .leading)

                            // Profile Image or Placeholder
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)

                                Text(entry.user.prefix(1))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }

                            // User Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.user) // Full Name
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .foregroundColor(.primary)

                                Text("\(entry.points) pts")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Badge Icon
                            let badges = GamificationManager.shared.getBadges(for: entry.user, context: context)
                            if !badges.isEmpty {
                                Image(systemName: "rosette")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.yellow)
                                    .padding(.trailing, 8)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Leaderboard")
        .onAppear {
            loadLeaderboardData()
        }
    }

    private func loadLeaderboardData() {
        let rawData = GamificationManager.shared.getLeaderboardData(context: context)
        leaderboardData = rawData
            .sorted(by: { $0.value > $1.value })
            .map { (user: $0.key, points: $0.value, image: "placeholder") } // Replace "placeholder" with a valid image if available
    }
    // Helper to get initials for users
    private func getInitials(for name: String) -> String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))"
        }
        return "\(name.prefix(2))"
    }
}
