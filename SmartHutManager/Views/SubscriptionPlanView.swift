import SwiftUI

struct SubscriptionPlanView: View {
    @Binding var selectedPlan: String
    var updatePlanInFirebase: (String) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            // "Choose Your Plan" Header
            Text("Choose Your Plan")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding(.leading)
                .padding(.top)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Starter Plan Card
                    SubscriptionCardView(
                        title: "Starter",
                        price: "Free",
                        description: "Quick video messages",
                        features: [
                            "Up to 50 Creators Lite",
                            "Up to 25 videos/person",
                            "Up to 5 mins/video"
                        ],
                        isSelected: selectedPlan == "Starter",
                        buttonAction: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedPlan = "Starter"
                                updatePlanInFirebase("Starter")
                            }
                        }
                    )

                    // Business Plan Card
                    SubscriptionCardView(
                        title: "Business",
                        price: "$12.50 /mo",
                        description: "Advanced recording & analytics",
                        features: [
                            "Unlimited Creators",
                            "Unlimited videos",
                            "Unlimited recording length"
                        ],
                        isSelected: selectedPlan == "Business",
                        buttonAction: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedPlan = "Business"
                                updatePlanInFirebase("Business")
                            }
                        }
                    )

                    // Premium Plan Card
                    SubscriptionCardView(
                        title: "Premium",
                        price: "$29.99 /mo",
                        description: "All features unlocked",
                        features: [
                            "Everything in Starter & Business",
                            "Custom branding",
                            "Advanced analytics",
                            "Priority support"
                        ],
                        isSelected: selectedPlan == "Premium",
                        buttonAction: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                selectedPlan = "Premium"
                                updatePlanInFirebase("Premium")
                            }
                        }
                    )
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .background(Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)) // Clean background
        .navigationTitle("Settings")
    }
}

struct SubscriptionCardView: View {
    let title: String
    let price: String
    let description: String
    let features: [String]
    let isSelected: Bool
    let buttonAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
                Text(price)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            Text(description)
                .font(.headline)
                .foregroundColor(.black) // Updated text color to black

            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.black) // Updated text color to black
                    }
                }
            }

            Button(action: buttonAction) {
                Text(isSelected ? "Selected" : "Choose Plan")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(isSelected ? Color.blue.opacity(0.7) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(width: 300, height: 350) // Fixed size for all cards
        .background(Color.white) // Ensure consistency in dark mode
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(isSelected ? 1.05 : 1.0) // Subtle animation for selection
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
    }
}
