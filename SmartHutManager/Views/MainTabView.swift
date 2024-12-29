import SwiftUI
import CoreData

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager // Add DeletedItemsManager here
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)])
    var tradesmen: FetchedResults<Tradesmen>
    
    let viewContext: NSManagedObjectContext
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true // Track dark mode state

    var body: some View {
        TabView {
            if authViewModel.userRole == "admin" {
                CRMView()
                    .tabItem {
                        Label("Clients", systemImage: "person.3.fill")
                    }
                
                JobSchedulerView(userName: "Admin") // Pass "Admin" as the name for admins
                    .environmentObject(deletedItemsManager) // Inject DeletedItemsManager here
                    .tabItem {
                        Label("Scheduler", systemImage: "calendar")
                    }
                
                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "message.fill")
                    }
                
                NavigationView {
                    if let userEmail = authViewModel.currentUserEmail,
                       let currentTradesman = tradesmen.first(where: { $0.email?.lowercased() == userEmail }) {
                        TradesmenDetailView(tradesman: currentTradesman)
                    } else {
                        NoTradesmenView()
                    }
                }
                .tabItem {
                    Label("Leaderboards", systemImage: "wrench.fill")
                }
                
                SettingsView()
                    .environmentObject(deletedItemsManager) // Inject DeletedItemsManager here
                    .tabItem {
                        Label("More", systemImage: "gearshape.fill")
                    }
            } else if authViewModel.userRole == "technician" {
                let userName = tradesmen.first(where: { $0.email?.lowercased() == authViewModel.currentUserEmail })?.name ?? "Unknown"
                
                JobSchedulerView(userName: userName)
                    .environmentObject(deletedItemsManager) // Inject DeletedItemsManager here
                    .tabItem {
                        Label("Scheduler", systemImage: "calendar")
                    }
                
                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "message.fill")
                    }
                
                SettingsView()
                    .environmentObject(deletedItemsManager) // Inject DeletedItemsManager here
                    .tabItem {
                        Label("More", systemImage: "gearshape.fill")
                    }
            }
        }
        .tint(Color.blue) // Selected tab color: Always blue
        .onAppear {
            configureTabBarAppearance() // Apply tab bar styling
        }
    }

    // MARK: - Tab Bar Appearance Configuration
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()

        // Configure the background and separator line
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground // Background color matches system background
        appearance.shadowColor = UIColor.systemGray4 // Keep the separator line visible at the top of the tab bar

        // Configure the unselected item tint color
        UITabBar.appearance().unselectedItemTintColor = isDarkMode ? UIColor.lightGray : UIColor.darkGray
        
        // Ensure the selected item tint color is always blue
        UITabBar.appearance().tintColor = UIColor.systemBlue

        // Apply the configured appearance to the tab bar
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance // Consistent styling for scrollable tabs
    }
}
