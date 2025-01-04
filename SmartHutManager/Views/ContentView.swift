import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var alertViewModel: AlertViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager

    @State private var showAlerts = false

    var body: some View {
        ZStack {
            // Main content
            NavigationView {
                if authViewModel.isUserSignedIn {
                    MainTabView(viewContext: viewContext)
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(authViewModel)
                        .environmentObject(deletedItemsManager)
                } else {
                    SignInView()
                        .environmentObject(authViewModel)
                }
            }

            // Persistent Alert Button Overlay
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Spacer()
                        AlertButton(
                            alertCount: alertViewModel.alertCount,
                            hasNewAlert: alertViewModel.hasNewAlert,
                            onTap: {
                                showAlerts = true
                                alertViewModel.markAlertsAsRead()
                            }
                        )
                        .padding(.trailing, 60) // Adjust horizontal position
                        .padding(.top, geometry.safeAreaInsets.top + 60) // Position below the status bar area
                    }
                    Spacer()
                }
            }
        }
        .edgesIgnoringSafeArea(.top) // Ensure the button respects the safe area
        .sheet(isPresented: $showAlerts) {
            AlertsView()
                .environmentObject(alertViewModel)
        }
    }
}
