import SwiftUI
import LocalAuthentication
import FirebaseFirestore
import MessageUI

struct TradesmanAccountSection: View {
    let tradesman: Tradesmen?

    @State private var isPersonalInfoVisible: Bool = false
    @State private var authenticationFailed: Bool = false
    @State private var companyID: String? = nil
    @State private var isLoading = true
    @State private var isShowingMailView = false
    @State private var emailErrorMessage: String? = nil

    var body: some View {
        if let tradesman = tradesman {
            VStack(alignment: .leading, spacing: 16) {
                // Header with Name, Job Title, and Image/Icon
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tradesman.name ?? "Unknown")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(tradesman.jobTitle ?? "Unknown Job Title")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.top, 16)

                Divider()

                // Display the Company ID
                if isLoading {
                    ProgressView()
                } else if let companyID = companyID {
                    HStack {
                        Text("Company ID:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(companyID)
                            .font(.body)
                            .foregroundColor(.secondary)

                        Spacer()

                        // Button to send Company ID via email
                        Button(action: {
                            sendCompanyIDEmail(to: "technician@example.com", companyID: companyID)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.blue)
                                Text("Send")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                } else {
                    Text("Company ID not available.")
                        .foregroundColor(.red)
                        .padding()
                }

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
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
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
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.horizontal)
            .onAppear {
                fetchCompanyID()
            }
        } else {
            Text("No tradesman available")
                .foregroundColor(.gray)
                .font(.system(size: 16))
                .padding()
        }
    }

    // MARK: - Fetch Company ID
    private func fetchCompanyID() {
        guard let email = tradesman?.email else {
            print("Tradesman email is nil.")
            return
        }

        let db = Firestore.firestore()
        isLoading = true

        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching company ID: \(error.localizedDescription)")
                    self.companyID = nil
                } else if let document = snapshot?.documents.first {
                    if let fetchedCompanyID = document.data()["companyID"] as? String {
                        self.companyID = fetchedCompanyID
                        print("Company ID fetched successfully: \(fetchedCompanyID)")
                    } else {
                        print("Company ID field is missing in the document.")
                        self.companyID = nil
                    }
                } else {
                    print("No matching user found for email: \(email)")
                    self.companyID = nil
                }
                self.isLoading = false
            }
        }
    }

    // MARK: - Send Email
    private func sendCompanyIDEmail(to email: String, companyID: String) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.setToRecipients([email])
            mailComposeViewController.setSubject("Company ID for Registration")
            mailComposeViewController.setMessageBody("Your Company ID for registration is: \(companyID)", isHTML: false)

            // Use UIWindowScene to present the email composer
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(mailComposeViewController, animated: true)
            }
        } else {
            emailErrorMessage = "Unable to send email. Please configure your email account."
        }
    }

    // MARK: - Personal Info View
    @ViewBuilder
    private func personalInfoView(tradesman: Tradesmen) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if let phoneNumber = tradesman.phoneNumber, !phoneNumber.isEmpty {
                InfoRow(icon: "phone.fill", text: phoneNumber, iconColor: .green) {
                    if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            if let email = tradesman.email, !email.isEmpty {
                InfoRow(icon: "envelope.fill", text: email, iconColor: .orange) {
                    if let url = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            if let address = tradesman.address, !address.isEmpty {
                InfoRow(icon: "mappin.and.ellipse", text: address, iconColor: .red) {
                    if let url = URL(string: "http://maps.apple.com/?q=\(address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"),
                       UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .padding(20)
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
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
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
