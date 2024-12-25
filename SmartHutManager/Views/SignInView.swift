import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var currentQuoteIndex = 0
    @State private var isAnimating = false

    private let quotes = [
        "Measuring twice, cutting once... Logging you in!",
        "Your business, your empire. Let’s load it up!",
        "Taking care of business, one click at a time.",
        "Signing you in... Just like a pro technician!",
        "Fetching your data. Hope you like fast service!"
    ]

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Main Sign-In Content
            VStack(spacing: 20) {
                Spacer()

                // App Title
                Text("SmartHutManager")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 5)

                // Subtitle
                Text("Manage your business like a pro!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 40)

                // Input Fields
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .autocapitalization(.none)
                        .foregroundColor(.black) // Ensure input text is black
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .padding(.horizontal, 30)
                        .textFieldStyle(PlainTextFieldStyle()) // Explicitly apply a plain text style

                    SecureField("Password", text: $password)
                        .foregroundColor(.black) // Ensure input text is black
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .padding(.horizontal, 30)
                        .textFieldStyle(PlainTextFieldStyle()) // Explicitly apply a plain text style
                }

                // Error Message
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                // Sign-In Button
                Button(action: {
                    authViewModel.signIn(email: email, password: password)
                }) {
                    HStack {
                        Image(systemName: "arrow.forward.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text("Sign In")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.blue]),
                        startPoint: .leading,
                        endPoint: .trailing)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                    .shadow(radius: 5)
                }
                .padding(.top, 20)

                Spacer()
            }
            .padding()

            // Loading State with Funny Quotes
            if authViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        // Quote inside a card view
                        quoteCardView(quote: quotes[currentQuoteIndex])
                            .id(currentQuoteIndex) // Ensure proper transition between quotes

                        // Rotating Wrench Icon
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .rotationEffect(isAnimating ? .degrees(360) : .degrees(0))
                            .onChange(of: isAnimating) {
                                withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                                    isAnimating = true
                                }
                            }
                            .onAppear {
                                isAnimating = true
                            }
                    }
                }
                .onAppear(perform: startQuoteAnimation)
            }
        }
    }

    // Updates the quote every 3 seconds
    private func startQuoteAnimation() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentQuoteIndex = (currentQuoteIndex + 1) % quotes.count
            }
        }
    }

    // MARK: - Card View for Quote
    private func quoteCardView(quote: String) -> some View {
        VStack {
            Text(quote)
                .font(.headline)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 40)
    }
}
