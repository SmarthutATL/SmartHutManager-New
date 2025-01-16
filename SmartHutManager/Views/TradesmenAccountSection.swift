import SwiftUI
import FirebaseAuth
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
    @State private var userName: String? = nil
    @State private var userRole: String? = nil
    @State private var userFullName: String? = nil // Update to hold the full name
    @State private var companyName: String? = nil
    @State private var companyLogo: String = "smarthut_logo" // Default to the same logo as SplashScreenView
    

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
                        Text(userFullName ?? "Unknown Name")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)

                        Text(userRole ?? "Unknown Job Title")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.top, 16)

                Divider()

                // Display the Company Information
                if isLoading {
                    ProgressView()
                } else if let companyID = companyID {
                    VStack(alignment: .center, spacing: 12) {
                        // Company Logo
                        Image(companyLogo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .cornerRadius(12) // Match the container's roundness
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                        // Company Name
                        if let name = companyName {
                            Text(name)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }

                        // Company ID Card
                        VStack(spacing: 4) {
                            Text("Company ID")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(companyID)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity) // Stretch to match width
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        )
                        .padding(.horizontal)

                        // Send Email Button
                        Button(action: {
                            sendCompanyIDEmail(to: "technician@example.com", companyID: companyID)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                Text("Send CompanyID to Technician")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity) // Makes the container stretch to screen width
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal) // Adds padding around the edges of the screen
                } else {
                    Text("Company information not available.")
                        .font(.callout)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                
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
                print("[Debug] userFullName before view appears: \(userFullName ?? "nil")")
                fetchCompanyID()
                fetchUserTradesman()
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
        guard let user = Auth.auth().currentUser else {
            print("[Error] No authenticated user.")
            self.isLoading = false
            return
        }

        let db = Firestore.firestore()
        isLoading = true

        print("Fetching user data for authenticated UID: \(user.uid)")
        db.collection("users").document(user.uid).getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[Error] Failed to fetch user document: \(error.localizedDescription)")
                    self.resetUserData()
                } else if let document = document, document.exists {
                    let data = document.data()
                    print("Fetched User Data: \(String(describing: data))")
                    
                    // Update @State variables
                    self.companyID = data?["companyID"] as? String
                    self.companyName = data?["companyName"] as? String
                    
                    // Fetch tradesman details after fetching the companyID
                    self.fetchUserTradesman()
                } else {
                    print("[Error] No user document found for UID: \(user.uid)")
                    self.resetUserData()
                }
                self.isLoading = false
            }
        }
    }
    
    
    private func resetUserData() {
        self.companyID = nil
        self.companyName = nil
        self.userFullName = nil
        self.userRole = nil

        if let tradesman = self.tradesman {
            tradesman.phoneNumber = nil
            tradesman.address = nil
            tradesman.email = nil
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
    private func personalInfoView(tradesman: Tradesmen?) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            if let phoneNumber = tradesman?.phoneNumber, !phoneNumber.isEmpty {
                InfoRow(icon: "phone.fill", text: phoneNumber, iconColor: .green) {
                    if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            if let email = tradesman?.email, !email.isEmpty {
                InfoRow(icon: "envelope.fill", text: email, iconColor: .orange) {
                    if let url = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            if let address = tradesman?.address, !address.isEmpty {
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

    // Add this method inside TradesmanAccountSection
    private func fetchUserTradesman() {
        guard let email = Auth.auth().currentUser?.email else {
            print("[Error] User email is nil.")
            self.isLoading = false
            return
        }

        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("[Firestore] Fetching tradesman for normalized email: \(normalizedEmail)")

        let db = Firestore.firestore()
        db.collection("tradesmen").whereField("email", isEqualTo: normalizedEmail).getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[Error] Failed to fetch tradesman: \(error.localizedDescription)")
                    self.resetUserData()
                    return
                }

                guard let document = snapshot?.documents.first else {
                    print("[Error] No tradesman found for email: \(normalizedEmail)")
                    self.resetUserData()
                    return
                }

                let data = document.data()
                print("[Firestore] Fetched tradesman document data: \(data)")

                // Safely unwrap and concatenate firstName and lastName
                let firstName = data["firstName"] as? String ?? "Unknown"
                let lastName = data["lastName"] as? String ?? "Name"
                self.userFullName = "\(firstName) \(lastName)"
                
                // Optionally update the user role
                self.userRole = data["jobTitle"] as? String ?? "Unknown Role"
                
                self.isLoading = false
            }
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
