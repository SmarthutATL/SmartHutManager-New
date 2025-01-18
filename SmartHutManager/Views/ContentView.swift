import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var alertViewModel: AlertViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager

    @State private var showAlerts = false
    @State private var showChat = false // State for presenting the Chat View

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
            if authViewModel.isUserSignedIn {
                GeometryReader { geometry in
                    VStack {
                        HStack {
                            Spacer() // Pushes the buttons to the right
                            
                            // Chat Button to the left of Alert Button
                            ChatButton(hasNewMessage: true) {
                                showChat = true // Trigger the chat view
                            }
                            .padding(.trailing, 15) // Space between ChatButton and AlertButton
                            
                            // Alert Button remains in its exact position
                            AlertButton(
                                alertCount: alertViewModel.alertCount,
                                hasNewAlert: alertViewModel.hasNewAlert,
                                onTap: {
                                    showAlerts = true
                                    alertViewModel.markAlertsAsRead()
                                }
                            )
                            .padding(.trailing, 60) // Horizontal position remains unchanged
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 65) // Vertical position remains unchanged
                        Spacer() // Pushes content to the top
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.top) // Ensure the button respects the safe area
        .sheet(isPresented: $showAlerts) {
            AlertsView()
                .environmentObject(alertViewModel)
        }
        .sheet(isPresented: $showChat) {
            ChatView() // Replace with the actual chat view
        }
    }
}
