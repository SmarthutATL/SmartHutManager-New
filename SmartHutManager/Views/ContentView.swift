import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showSplashScreen = true // Control splash visibility

    var body: some View {
        ZStack {
            if showSplashScreen {
                // Display the SplashScreenView
                SplashScreenView()
                    .transition(.opacity)
                    .onAppear {
                        // Force splash screen to stay for 10 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            withAnimation {
                                showSplashScreen = false
                            }
                        }
                    }
            } else {
                // Show content based on authentication state
                if authViewModel.isUserSignedIn {
                    MainTabView(viewContext: viewContext) // Explicitly pass viewContext
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(authViewModel)
                } else {
                    SignInView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}
