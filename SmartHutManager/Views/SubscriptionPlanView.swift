import SwiftUI

struct SubscriptionPlanView: View {
    @Binding var selectedPlan: String
    var updatePlanInFirebase: (String) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            // Header
            Text("Select Your Service Package")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.leading, 16)
                .padding(.top, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Basic Plan
                    ServiceCardView(
                        title: "Basic Package",
                        price: "$299",
                        description: "Smart home essentials",
                        features: [
                            "1 Smart Lock",
                            "1 Smart Thermostat",
                            "1 Doorbell Camera",
                            "Free Installation"
                        ],
                        isSelected: selectedPlan == "Basic",
                        buttonAction: {
                            withAnimation(.smooth) {
                                selectedPlan = "Basic"
                                updatePlanInFirebase("Basic")
                            }
                        }
                    )
                    
                    // Advanced Plan
                    ServiceCardView(
                        title: "Advanced Package",
                        price: "$499",
                        description: "Enhanced smart home setup",
                        features: [
                            "Everything in Basic",
                            "3 Smart Plugs",
                            "1 Interior Camera",
                            "Ceiling Fan Installation"
                        ],
                        isSelected: selectedPlan == "Advanced",
                        buttonAction: {
                            withAnimation(.smooth) {
                                selectedPlan = "Advanced"
                                updatePlanInFirebase("Advanced")
                            }
                        }
                    )
                    
                    // Premium Plan
                    ServiceCardView(
                        title: "Premium Package",
                        price: "$999",
                        description: "Full-featured smart home",
                        features: [
                            "Everything in Advanced",
                            "2 Exterior Cameras",
                            "Custom Lighting Setup",
                            "Home Theater Integration"
                        ],
                        isSelected: selectedPlan == "Premium",
                        buttonAction: {
                            withAnimation(.smooth) {
                                selectedPlan = "Premium"
                                updatePlanInFirebase("Premium")
                            }
                        }
                    )
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 10)

            Spacer()
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Service Packages")
    }
}

// MARK: - ServiceCardView
struct ServiceCardView: View {
    let title: String
    let price: String
    let description: String
    let features: [String]
    let isSelected: Bool
    let buttonAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
                Text(price)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 4)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.top, 4)

            Button(action: buttonAction) {
                Text(isSelected ? "Selected" : "Choose Plan")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(isSelected ? Color.blue.opacity(0.8) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 320, height: 360)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
    }
}

