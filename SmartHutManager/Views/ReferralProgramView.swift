import SwiftUI

struct ReferralProgramView: View {
    @State private var referralCode: String = "ABC123"
    @State private var rewardDetails: String = "10% Discount for both referrer and referee"
    @State private var referralsMade: Int = 0
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 20) {
        
            // Referral Code Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Referral Code")
                    .font(.headline)
                Text(referralCode)
                    .font(.body)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            // Reward Details Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Reward Details")
                    .font(.headline)
                Text(rewardDetails)
                    .font(.body)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.green, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            // Referral Count Section
            VStack(alignment: .center, spacing: 10) {
                Text("Referrals Made")
                    .font(.headline)
                Text("\(referralsMade)")
                    .font(.title)
                    .bold()
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            // Share Referral Code Button
            Button(action: shareReferralCode) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                    Text("Share Referral Code")
                        .fontWeight(.semibold)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            // Send Code to Admin Button
            Button(action: sendReferralToAdmin) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.headline)
                    Text("Send Referral to Admin")
                        .fontWeight(.semibold)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("Referral Program")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Share Referral Code
    private func shareReferralCode() {
        let activityVC = UIActivityViewController(
            activityItems: [
                "Join SmartHutManager and use my referral code \(referralCode) to get 10% off! Refer SmartHutManager as your #1 CRM!"
            ],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
    }

    // MARK: - Send Referral to Admin
    private func sendReferralToAdmin() {
        let subject = "Join SmartHutManager!"
        let body = """
        Hi there,

        Join SmartHutManager as your #1 CRM for managing your business effectively! Use my referral code \(referralCode) to get started with a special 10% discount.

        Best regards,
        [Your Name]
        """
        
        if let url = URL(string: "mailto:?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        } else {
            showAlert = true
            alertMessage = "Unable to open email client."
        }
    }
}
