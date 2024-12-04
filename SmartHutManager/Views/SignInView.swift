import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    @EnvironmentObject var authViewModel: AuthViewModel  // Access AuthViewModel

    var body: some View {
        VStack {
            Spacer()

            Text("Sign In to SmartHutManager")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 40)

            // Email and password input fields
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal, 20)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal, 20)

            // Error message display
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            Button(action: {
                authViewModel.signIn(email: email, password: password)  // Use the ViewModel to sign in
            }) {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)

            Spacer()
        }
    }
}
