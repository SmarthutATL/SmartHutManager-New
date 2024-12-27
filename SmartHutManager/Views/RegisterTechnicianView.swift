import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterTechnicianView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Technician Registration")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }
                
                if isLoading {
                    ProgressView()
                } else {
                    Button("Register Technician") {
                        registerTechnician()
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Register Technician")
        }
    }
    
    private func registerTechnician() {
        isLoading = true
        let db = Firestore.firestore()
        
        // Fetch the admin's companyID
        guard let currentUser = Auth.auth().currentUser else {
            self.errorMessage = "Error: Admin not logged in"
            self.isLoading = false
            return
        }
        
        db.collection("users").document(currentUser.uid).getDocument { document, error in
            if let error = error {
                self.errorMessage = "Error fetching admin data: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            guard let companyID = document?.data()?["companyID"] as? String else {
                self.errorMessage = "Company ID not found for admin."
                self.isLoading = false
                return
            }
            
            // Register technician with the admin's companyID
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = "Error: \(error.localizedDescription)"
                        self.isLoading = false
                    } else if let userID = authResult?.user.uid {
                        db.collection("users").document(userID).setData([
                            "email": email,
                            "role": "technician",
                            "companyID": companyID
                        ]) { error in
                            DispatchQueue.main.async {
                                self.isLoading = false
                                if let error = error {
                                    self.errorMessage = "Error saving technician data: \(error.localizedDescription)"
                                } else {
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
