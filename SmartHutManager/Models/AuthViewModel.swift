import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import SwiftUI

class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    
    @Published var isUserSignedIn = false
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var userRole: String = ""
    @Published var currentUserEmail: String?
    @Published var userFirstName: String?
    @Published var userFullName: String?

    private var db = Firestore.firestore()
    
    

    init() {
        print("[AuthViewModel] Initialized.")
        checkIfUserIsSignedIn()
    }

    // MARK: - Check If User is Signed In
    private func checkIfUserIsSignedIn() {
        print("[Auth] Checking if user is already signed in...")
        isLoading = true

        if let currentUser = Auth.auth().currentUser {
            let uid = currentUser.uid
            print("[Auth] User is signed in with UID: \(uid), email: \(currentUser.email ?? "unknown email")")
            
            // Fetch user data from Firestore
            fetchUserData(uid: uid)
        } else {
            print("[Auth] No user currently signed in.")
            isLoading = false
        }
    }
    
    private func fetchUserData(uid: String) {
        print("[Firestore] Fetching user data for UID: \(uid)")
        db.collection("users").document(uid).getDocument { [weak self] (document, error) in
            if let error = error {
                print("[Firestore Error] Failed to fetch user data: \(error.localizedDescription)")
                self?.errorMessage = "Unable to fetch user data. Please contact support."
                self?.isLoading = false
            } else if let document = document, document.exists {
                if let data = document.data() {
                    let role = data["role"] as? String ?? "Unknown Role"
                    let email = data["email"] as? String ?? "Unknown Email"
                    let firstName = data["firstName"] as? String ?? "User"

                    DispatchQueue.main.async {
                        print("[Firestore] User Role: \(role), Email: \(email), First Name: \(firstName)")
                        self?.userRole = role
                        self?.currentUserEmail = email.lowercased()
                        self?.userFirstName = firstName // Store the first name
                        self?.isUserSignedIn = true
                        self?.isLoading = false
                    }
                } else {
                    print("[Firestore Error] Data is missing or invalid.")
                    self?.errorMessage = "User information is missing or invalid. Please contact support."
                    self?.isLoading = false
                }
            } else {
                print("[Firestore] User document does not exist.")
                self?.errorMessage = "User not found. Please contact support."
                self?.isLoading = false
            }
        }
    }
    // MARK: - Sign In
    func signIn(email: String, password: String) {
        print("[Auth] Attempting sign-in with email: \(email)")
        isLoading = true
        let lowercasedEmail = email.lowercased()

        Auth.auth().signIn(withEmail: lowercasedEmail, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    print("[Auth Error] Sign-in failed for email: \(email), error: \(error.localizedDescription)")

                    // Error handling
                    switch AuthErrorCode(rawValue: error.code) {
                    case .wrongPassword:
                        self?.errorMessage = "Incorrect password. Please try again."
                        print("[Auth Error] Incorrect password.")
                    case .invalidEmail:
                        self?.errorMessage = "Invalid email format. Please enter a valid email."
                        print("[Auth Error] Invalid email format.")
                    case .userNotFound:
                        self?.errorMessage = "No account found with this email. Please sign up."
                        print("[Auth Error] No user found for email.")
                    default:
                        self?.errorMessage = "Unexpected error: \(error.localizedDescription)"
                        print("[Auth Error] Unhandled error: \(error.localizedDescription)")
                    }

                    self?.isLoading = false
                } else if let user = result?.user {
                    print("[Auth] Sign-in successful for user: \(user.email ?? "unknown email"), UID: \(user.uid)")
                    self?.currentUserEmail = user.email?.lowercased()
                    self?.fetchUserRole(email: user.email?.lowercased() ?? "")
                } else {
                    print("[Auth Error] Sign-in result returned nil.")
                    self?.isLoading = false
                }
            }
        }
    }

    // MARK: - Fetch User Role
    private func fetchUserRole(email: String) {
        print("[Firestore] Fetching role for email: \(email)")
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { [weak self] (snapshot, error) in
            if let error = error as NSError? {
                print("[Firestore Error] Failed to fetch role for email: \(email), error: \(error.localizedDescription)")

                // Handle Firestore errors
                switch error.code {
                case FirestoreErrorCode.permissionDenied.rawValue:
                    self?.errorMessage = "Permission denied. Please contact support."
                case FirestoreErrorCode.unavailable.rawValue:
                    self?.errorMessage = "Firestore service is currently unavailable. Please try again later."
                default:
                    self?.errorMessage = "Failed to fetch role: \(error.localizedDescription)"
                }

                self?.isLoading = false
                return
            }

            guard let snapshot = snapshot, !snapshot.isEmpty else {
                print("[Firestore] No documents found for email: \(email).")
                self?.errorMessage = "No role information available. Please contact support."
                self?.isLoading = false
                return
            }

            print("[Firestore] \(snapshot.documents.count) document(s) found for email: \(email).")

            if let document = snapshot.documents.first {
                if let role = document.data()["role"] as? String {
                    DispatchQueue.main.async {
                        print("[Firestore] Role successfully retrieved: \(role) for email: \(email).")
                        self?.userRole = role
                        self?.isUserSignedIn = true
                        self?.isLoading = false
                    }
                } else {
                    print("[Firestore Error] Role field is missing or invalid in Firestore document for email: \(email).")
                    self?.errorMessage = "Role data is missing or invalid. Please contact support."
                    self?.isLoading = false
                }
            }
        }
    }

    // MARK: - Assign Role
    func assignRoleToUser(email: String, role: String, completion: @escaping (Bool, String?) -> Void) {
        print("[Functions] Assigning role \(role) to user: \(email)")
        let functions = Functions.functions()
        functions.httpsCallable("assignRole").call(["email": email, "role": role]) { result, error in
            if let error = error as NSError? {
                print("[Functions Error] Error assigning role: \(error.localizedDescription)")
                completion(false, "Error assigning role: \(error.localizedDescription)")
            } else if let resultData = result?.data as? [String: Any] {
                print("[Functions] Role assigned successfully: \(resultData["message"] ?? "No message")")
                completion(true, resultData["message"] as? String)
            }
        }
    }

    // MARK: - Save User to Firestore
    func saveUserToFirestore(uid: String, email: String, role: String) {
        print("[Firestore] Saving user to Firestore with UID: \(uid), email: \(email), role: \(role)")
        db.collection("users").document(uid).setData([
            "email": email,
            "role": role,
            "createdAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("[Firestore Error] Error saving user to Firestore: \(error.localizedDescription)")
            } else {
                print("[Firestore] User successfully saved to Firestore.")
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        print("[Auth] Attempting to sign out...")
        do {
            try Auth.auth().signOut()
            print("[Auth] Sign-out successful.")
            self.isUserSignedIn = false
            self.userRole = ""
            self.currentUserEmail = nil
            self.errorMessage = nil
        } catch {
            print("[Auth Error] Sign-out failed: \(error.localizedDescription)")
            self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
