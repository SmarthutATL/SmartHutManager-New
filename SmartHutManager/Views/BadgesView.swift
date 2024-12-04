import SwiftUI

struct BadgesView: View {
    let tradesmanName: String
    @State private var badges: [String] = []
    @Environment(\.managedObjectContext) var context // Access Core Data context

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if badges.isEmpty {
                    // Display a message when no badges are available
                    VStack {
                        Image(systemName: "rosette")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        Text("No badges available.")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    // Display badges
                    ForEach(badges, id: \.self) { badge in
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .frame(width: 20, height: 20)
                            Text(badge)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .shadow(radius: 3)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(tradesmanName)'s Badges")
        .onAppear {
            loadBadges(for: tradesmanName)
        }
    }

    private func loadBadges(for tradesman: String) {
        // Fetch badges from GamificationManager with the Core Data context
        badges = GamificationManager.shared.getBadges(for: tradesman, context: context)
    }
}
