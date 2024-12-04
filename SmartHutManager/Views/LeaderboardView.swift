import SwiftUI

struct LeaderboardView: View {
    @Environment(\.managedObjectContext) var context // Access Core Data context
    @State private var leaderboardData: [(user: String, points: Int, image: String)] = [] // Include image for users

    var body: some View {
        VStack {
            // Top 3 Section
            if leaderboardData.count >= 3 {
                HStack(spacing: 16) {
                    ForEach(leaderboardData.prefix(3), id: \.user) { entry in
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
                                    .frame(width: 90, height: 90)
                                Text(entry.user.prefix(1))
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }

                            Text(entry.user)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text("\(entry.points) pts")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
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
                        HStack {
                            Text("#\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(width: 30)

                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                Text(entry.user.prefix(1))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading) {
                                Text(entry.user)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                Text("\(entry.points) pts")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            let badges = GamificationManager.shared.getBadges(for: entry.user, context: context)
                            if !badges.isEmpty {
                                Image(systemName: "rosette")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
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
}
