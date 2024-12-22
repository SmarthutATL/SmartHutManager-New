import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        if authViewModel.isUserSignedIn {
            MainTabView(viewContext: viewContext)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(authViewModel)
        } else {
            SignInView()
                .environmentObject(authViewModel)
        }
    }
}
