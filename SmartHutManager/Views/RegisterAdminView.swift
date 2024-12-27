import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RegisterAdminView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Admin Registration")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }
                
                if isLoading {
                    ProgressView()
                } else {
                    Button("Register Admin") {
                        registerAdmin()
                    }
                    .disabled(email.isEmpty || password.isEmpty)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            .navigationTitle("Register Admin")
        }
    }
    
    private func registerAdmin() {
        isLoading = true
        let db = Firestore.firestore()
        
        // Generate a random companyID
        let companyID = UUID().uuidString.prefix(8).uppercased()
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    self.isLoading = false
                } else if let userID = authResult?.user.uid {
                    // Store admin with generated companyID in Firestore
                    db.collection("users").document(userID).setData([
                        "email": email,
                        "role": "admin",
                        "companyID": companyID
                    ]) { error in
                        DispatchQueue.main.async {
                            self.isLoading = false
                            if let error = error {
                                self.errorMessage = "Error saving admin data: \(error.localizedDescription)"
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
