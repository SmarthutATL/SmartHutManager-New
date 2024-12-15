import SwiftUI
import LocalAuthentication

struct TradesmanAccountSection: View {
    let tradesman: Tradesmen?

    @State private var isPersonalInfoVisible: Bool = false
    @State private var authenticationFailed: Bool = false

    var body: some View {
        if let tradesman = tradesman {
            VStack(alignment: .leading, spacing: 16) {
                // Header with Name, Job Title, and Image/Icon
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill") // Replace with actual image if available
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80) // Larger image
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tradesman.name ?? "Unknown")
                            .font(.system(size: 24, weight: .semibold)) // Larger text
                            .foregroundColor(.primary)
                        
                        Text(tradesman.jobTitle ?? "Unknown Job Title")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.top, 16) // Add padding from top of the screen

                Divider()

                // Personal Information Section
                VStack(alignment: .leading, spacing: 16) {
                    if isPersonalInfoVisible {
                        personalInfoView(tradesman: tradesman)
                    } else {
                        Button(action: authenticate) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.red)
                                Text("Unlock Personal Info")
                                    .font(.system(size: 18)) // Larger button text
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity) // Make the button full width
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                if authenticationFailed {
                    Text("Authentication failed. Please try again.")
                        .font(.system(size: 16)) // Larger error message text
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }

                Spacer() // Pushes content to the top
            }
            .padding(.horizontal)
        } else {
            Text("No tradesman available")
                .foregroundColor(.gray)
                .font(.system(size: 16))
                .padding()
        }
    }

    // MARK: - Personal Info View
    @ViewBuilder
    private func personalInfoView(tradesman: Tradesmen) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Phone Number
            if let phoneNumber = tradesman.phoneNumber, !phoneNumber.isEmpty {
                InfoRow(icon: "phone.fill", text: phoneNumber, iconColor: .green) {
                    if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            // Email
            if let email = tradesman.email, !email.isEmpty {
                InfoRow(icon: "envelope.fill", text: email, iconColor: .orange) {
                    if let url = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            // Address
            if let address = tradesman.address, !address.isEmpty {
                InfoRow(icon: "mappin.and.ellipse", text: address, iconColor: .red) {
                    if let url = URL(string: "http://maps.apple.com/?q=\(address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .padding(20) // Add padding inside the card
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .cornerRadius(15)
    }

    // MARK: - InfoRow Component
    private struct InfoRow: View {
        let icon: String
        let text: String
        let iconColor: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(iconColor)
                    Text(text)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                        .underline()
                    Spacer() // Push content to the left
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle()) // Removes default button styling
        }
    }

    // MARK: - Authentication
    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate with Face ID to view personal information"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        self.isPersonalInfoVisible = true
                        self.authenticationFailed = false
                    } else {
                        self.authenticationFailed = true
                    }
                }
            }
        } else {
            authenticationFailed = true
        }
    }
}
