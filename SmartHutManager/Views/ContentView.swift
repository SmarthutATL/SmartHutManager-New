import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager // Add this line

    var body: some View {
        if authViewModel.isUserSignedIn {
            MainTabView(viewContext: viewContext)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(authViewModel)
                .environmentObject(deletedItemsManager) // Pass the DeletedItemsManager
        } else {
            SignInView()
                .environmentObject(authViewModel)
        }
    }
}
