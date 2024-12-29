import SwiftUI
import FirebaseFirestore

struct RegisterTechnicianView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var companyID = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isCompanyIDValid = false
    @State private var isCompanyIDInvalid = false
    @State private var connectedCompanyName: String? = nil
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Company ID Section
                    HStack {
                        TextField("Company ID", text: $companyID)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        // Validation State Icons
                        if isLoading {
                            ProgressView()
                                .transition(.opacity)
                        } else if isCompanyIDValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .transition(.opacity)
                        } else if isCompanyIDInvalid {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }
                    }

                    Button(action: verifyCompanyID) {
                        Text("Verify Company ID")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    if let companyName = connectedCompanyName, isCompanyIDValid {
                        Text("Connected to: \(companyName)")
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)
                    }

                    // Technician Details Section
                    TextField("Email Address", text: $email)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                    }

                    // Register Button
                    Button(action: registerTechnician) {
                        Text(isLoading ? "Registering..." : "Register Technician")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid() ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.top, 20)
                    }
                    .disabled(!isFormValid())

                    Spacer()
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Register Technician")
        }
    }

    // Reset validation states
    private func resetValidationStates() {
        isCompanyIDValid = false
        isCompanyIDInvalid = false
        connectedCompanyName = nil
        errorMessage = nil
    }

    private func verifyCompanyID() {
        guard companyID.count == 8 else {
            resetValidationStates()
            print("DEBUG: Company ID length is invalid.")
            return
        }

        print("DEBUG: Verifying Company ID: \(companyID)")
        isLoading = true
        resetValidationStates()

        let db = Firestore.firestore()

        db.collection("users")
            .whereField("companyID", isEqualTo: companyID)
            .whereField("role", isEqualTo: "admin")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        print("DEBUG: Firestore error: \(error.localizedDescription)")
                        errorMessage = "Error validating Company ID: \(error.localizedDescription)"
                        isCompanyIDInvalid = true
                        return
                    }

                    guard let document = snapshot?.documents.first else {
                        print("DEBUG: No matching admin found for Company ID: \(companyID)")
                        errorMessage = "Invalid Company ID. Please check with your admin."
                        isCompanyIDInvalid = true
                        return
                    }

                    print("DEBUG: Company ID is valid. Document: \(document.data())")
                    connectedCompanyName = document.data()["companyName"] as? String ?? "Unknown Company"
                    isCompanyIDValid = true
                }
            }
    }

    private func registerTechnician() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        guard isCompanyIDValid else {
            errorMessage = "Please verify the Company ID before registering."
            return
        }

        isLoading = true
        let db = Firestore.firestore()

        db.collection("registrationRequests").addDocument(data: [
            "email": email,
            "role": "technician",
            "companyID": companyID,
            "status": "pending"
        ]) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("DEBUG: Error saving registration request: \(error.localizedDescription)")
                    errorMessage = "Error saving registration request: \(error.localizedDescription)"
                } else {
                    print("DEBUG: Technician registration request saved successfully.")
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func isFormValid() -> Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        isCompanyIDValid
    }
}
