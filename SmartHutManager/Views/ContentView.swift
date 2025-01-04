import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var alertViewModel: AlertViewModel // Add AlertViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager

    @State private var showAlerts = false // State to control alert sheet

    var body: some View {
        NavigationView {
            if authViewModel.isUserSignedIn {
                MainTabView(viewContext: viewContext)
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(authViewModel)
                    .environmentObject(deletedItemsManager)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            AlertButton(alertCount: alertViewModel.alertCount) { // Pass `alertViewModel.alertCount` directly
                                showAlerts = true
                            }
                        }
                    }
                    .sheet(isPresented: $showAlerts) {
                        AlertsView()
                            .environmentObject(alertViewModel)
                    }
            } else {
                SignInView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
