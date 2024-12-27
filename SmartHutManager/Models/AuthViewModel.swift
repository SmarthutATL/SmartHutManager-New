import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isUserSignedIn = false
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var userRole: String = ""
    @Published var currentUserEmail: String?

    private var db = Firestore.firestore()

    init() {
        print("AuthViewModel initialized")
        checkIfUserIsSignedIn()
    }

    // Check if the user is already signed in and fetch their role
    private func checkIfUserIsSignedIn() {
        print("Checking if user is already signed in...")
        isLoading = true

        if let currentUser = Auth.auth().currentUser {
            print("User is signed in: \(currentUser.email ?? "unknown email")")
            currentUser.getIDTokenForcingRefresh(true) { [weak self] token, error in
                if let error = error {
                    print("Error refreshing token: \(error.localizedDescription)")
                    self?.isLoading = false
                    self?.errorMessage = "Session expired. Please log in again."
                    self?.signOut()
                } else {
                    print("Token refreshed successfully. Proceeding to fetch user role.")
                    self?.currentUserEmail = currentUser.email?.lowercased()
                    self?.fetchUserRole(email: currentUser.email?.lowercased() ?? "")
                }
            }
        } else {
            print("No user signed in.")
            isLoading = false
        }
    }

    // Sign-in function
    func signIn(email: String, password: String) {
        print("Attempting sign-in with email: \(email)")
        isLoading = true
        let lowercasedEmail = email.lowercased()

        Auth.auth().signIn(withEmail: lowercasedEmail, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    print("Sign-in error: \(error.localizedDescription)")

                    // Custom error handling based on Firebase error codes
                    switch AuthErrorCode(rawValue: error.code) {
                    case .wrongPassword:
                        self?.errorMessage = "Incorrect password. Please try again."
                    case .invalidEmail:
                        self?.errorMessage = "Invalid email format. Please enter a valid email."
                    case .userNotFound:
                        self?.errorMessage = "No account found with this email. Please sign up."
                    default:
                        self?.errorMessage = error.localizedDescription
                    }
                    
                    self?.isLoading = false
                } else if let email = result?.user.email {
                    print("Sign-in successful. Email: \(email)")
                    self?.currentUserEmail = email.lowercased()
                    self?.fetchUserRole(email: email.lowercased())
                } else {
                    print("Sign-in unexpected result: result and email are nil.")
                    self?.isLoading = false
                }
            }
        }
    }

    // Fetch the user role from Firestore
    private func fetchUserRole(email: String) {
        print("Fetching user role for email: \(email)")
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { [weak self] (snapshot, error) in
            if let error = error as NSError? {
                print("Error fetching user role: \(error.localizedDescription)")

                // Handle Firestore permission errors
                switch error.code {
                case FirestoreErrorCode.permissionDenied.rawValue:
                    self?.errorMessage = "You don't have permission to access this data. Please contact support."
                case FirestoreErrorCode.unavailable.rawValue:
                    self?.errorMessage = "Firestore is temporarily unavailable. Please try again later."
                default:
                    self?.errorMessage = "Failed to fetch user role: \(error.localizedDescription)"
                }

                self?.isLoading = false
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No matching document found for email: \(email)")
                self?.errorMessage = "User account found, but no role information is available. Please contact support."
                self?.isLoading = false
                return
            }

            if let role = documents.first?.data()["role"] as? String {
                DispatchQueue.main.async {
                    print("Successfully fetched role: \(role) for user: \(email)")
                    self?.userRole = role
                    self?.isUserSignedIn = true
                    self?.isLoading = false
                }
            } else {
                print("Role field not found for email: \(email)")
                self?.errorMessage = "User role data is missing. Please contact support."
                self?.isLoading = false
            }
        }
    }

    // Function to assign role to a user via Firebase Functions
    func assignRoleToUser(email: String, role: String, completion: @escaping (Bool, String?) -> Void) {
        let functions = Functions.functions()
        functions.httpsCallable("assignRole").call(["email": email, "role": role]) { result, error in
            if let error = error as NSError? {
                print("Error assigning role: \(error.localizedDescription)")
                completion(false, "Error assigning role: \(error.localizedDescription)")
            } else if let resultData = result?.data as? [String: Any] {
                print("Role assigned successfully: \(resultData["message"] ?? "No message")")
                completion(true, resultData["message"] as? String)
            }
        }
    }

    // Function to save user details to Firestore
    func saveUserToFirestore(uid: String, email: String, role: String) {
        db.collection("users").document(uid).setData([
            "email": email,
            "role": role,
            "createdAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error saving user to Firestore: \(error.localizedDescription)")
            } else {
                print("User successfully saved to Firestore.")
            }
        }
    }

    // Sign-out function
    func signOut() {
        print("Attempting to sign out...")
        do {
            try Auth.auth().signOut()
            print("Sign-out successful.")
            self.isUserSignedIn = false
            self.userRole = ""
            self.currentUserEmail = nil
            self.errorMessage = nil
        } catch {
            print("Failed to sign out: \(error.localizedDescription)")
            self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
