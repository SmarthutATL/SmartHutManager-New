import FirebaseAuth
import FirebaseFirestore

func createTechnician(email: String, password: String, authViewModel: AuthViewModel, completion: @escaping (Bool, String?) -> Void) {
    // Create user in Firebase Authentication
    Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
        if let error = error {
            completion(false, "Error creating technician: \(error.localizedDescription)")
            return
        }

        guard let uid = authResult?.user.uid else {
            completion(false, "Failed to get user ID after creating technician.")
            return
        }

        // Assign technician role
        authViewModel.assignRoleToUser(email: email, role: "technician") { success, message in
            if success {
                // Save user in Firestore
                authViewModel.saveUserToFirestore(uid: uid, email: email, role: "technician")
                completion(true, "Technician created and role assigned successfully.")
            } else {
                completion(false, message)
            }
        }
    }
}
