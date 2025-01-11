import SwiftUI
import CoreData

struct MarketingToolsView: View {
    let context: NSManagedObjectContext

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Send Promotions Card
                cardView {
                    NavigationLink(destination: PromotionalMessagesView()) {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsItem(icon: "envelope.fill", title: "Send Promotions", color: .blue)
                            Text("Send promotional emails or texts to customers, offering discounts or other incentives.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }

                // Referral Program Card
                cardView {
                    NavigationLink(destination: ReferralProgramView()) {
                        VStack(alignment: .leading, spacing: 12) {
                            SettingsItem(icon: "person.3.fill", title: "Referral Program", color: .green)
                            Text("Create referral programs to reward customers for referring others to your business.")
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .navigationTitle("Marketing Tools")
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    // Reusable card-style container
    private func cardView<Content: View>(
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
        )
    }
}
