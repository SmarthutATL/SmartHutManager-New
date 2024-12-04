import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel  // Access AuthViewModel for authentication logic

    var body: some View {
        // Check the authentication state and decide which view to show
        if authViewModel.isLoading {
            // Show splash screen while loading
            SplashScreenView()
        } else if authViewModel.isUserSignedIn {
            // If the user is signed in, show the main app content
            MainTabView()
        } else {
            // If the user is not signed in, show the sign-in screen
            SignInView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel()) // Inject the AuthViewModel for preview
}
