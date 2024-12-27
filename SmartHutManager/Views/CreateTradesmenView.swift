import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateTradesmanView: View {
    @State private var name = ""
    @State private var jobTitle = ""
    @State private var phoneNumber = ""
    @State private var address = ""
    @State private var email = ""
    @State private var password = "" // Add a password for user creation
    @State private var isLoading = false
    @State private var errorMessage: String?

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tradesman Info")) {
                    TextField("Full Name", text: $name)
                    TextField("Job Title", text: $jobTitle)
                    TextField("Phone Number", text: $phoneNumber)
                    TextField("Address", text: $address)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button("Create Tradesman") {
                    createTradesman()
                }
                .disabled(name.isEmpty || jobTitle.isEmpty || phoneNumber.isEmpty || address.isEmpty || email.isEmpty || password.isEmpty)
                .alert(isPresented: $isLoading) {
                    Alert(title: Text("Creating Tradesman..."))
                }
            }
            .navigationTitle("Create Tradesman")
        }
    }

    private func createTradesman() {
        isLoading = true
        errorMessage = nil

        // Create user in Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = "Error creating user: \(error.localizedDescription)"
                self.isLoading = false
                return
            }

            guard let userId = authResult?.user.uid else {
                self.errorMessage = "Failed to get user ID."
                self.isLoading = false
                return
            }

            // Save user to Firestore
            let db = Firestore.firestore()
            db.collection("users").document(userId).setData([
                "name": self.name,
                "jobTitle": self.jobTitle,
                "phoneNumber": self.phoneNumber,
                "address": self.address,
                "email": self.email,
                "role": "technician",
                "createdAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    self.errorMessage = "Error saving to Firestore: \(error.localizedDescription)"
                } else {
                    // Assign role to the user
                    self.authViewModel.assignRoleToUser(email: self.email, role: "technician") { success, message in
                        if !success {
                            self.errorMessage = message
                        } else {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                self.isLoading = false
            }
        }
    }
}
