import SwiftUI
import CoreData

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)])
    var tradesmen: FetchedResults<Tradesmen>
    
    let viewContext: NSManagedObjectContext
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true

    var body: some View {
        TabView {
            if authViewModel.userRole == "admin" {
                // Admin-specific tabs
                CRMView()
                    .tabItem {
                        Label("Clients", systemImage: "person.3.fill")
                    }
                
                JobSchedulerView(userName: "Admin")
                    .environmentObject(deletedItemsManager)
                    .tabItem {
                        Label("Scheduler", systemImage: "calendar")
                    }
                
                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "message.fill")
                    }
                
                // Leaderboards tab
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
                    .environmentObject(deletedItemsManager)
                    .tabItem {
                        Label("More", systemImage: "gearshape.fill")
                    }
            } else if authViewModel.userRole == "technician" {
                // Technician-specific tabs (reordered)
                let userName = tradesmen.first(where: { $0.email?.lowercased() == authViewModel.currentUserEmail })?.name ?? "Unknown"
                
                JobSchedulerView(userName: userName)
                    .environmentObject(deletedItemsManager)
                    .tabItem {
                        Label("Scheduler", systemImage: "calendar")
                    }
                
                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "message.fill")
                    }
                
                // Leaderboards tab
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
                    .environmentObject(deletedItemsManager)
                    .tabItem {
                        Label("More", systemImage: "gearshape.fill")
                    }
            }
        }
        .tint(Color.blue)
        .onAppear {
            configureTabBarAppearance()
        }
        .onChange(of: authViewModel.userRole) { newRole in
            print("User role updated to: \(newRole)")
            // Optional: Trigger additional updates if needed.
        }
    }

    // MARK: - Tab Bar Appearance Configuration
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()

        // Configure the background and separator line
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.systemGray4

        // Configure the unselected item tint color
        UITabBar.appearance().unselectedItemTintColor = isDarkMode ? UIColor.lightGray : UIColor.darkGray
        
        // Ensure the selected item tint color is always blue
        UITabBar.appearance().tintColor = UIColor.systemBlue

        // Apply the configured appearance to the tab bar
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
