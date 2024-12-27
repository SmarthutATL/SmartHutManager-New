import SwiftUI
import CoreData

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)])
    var tradesmen: FetchedResults<Tradesmen>
    
    let viewContext: NSManagedObjectContext
    
    var body: some View {
        TabView {
            if authViewModel.userRole == "admin" {
                CRMView()
                    .tabItem {
                        Label("CRM", systemImage: "person.3.fill")
                    }
                JobSchedulerView()
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
                    .tabItem {
                        Label("More", systemImage: "gearshape.fill")
                    }
            } else if authViewModel.userRole == "technician" {
                JobSchedulerView()
                    .tabItem {
                        Label("Scheduler", systemImage: "calendar")
                    }
                MessagesView()
                    .tabItem {
                        Label("Messages", systemImage: "message.fill")
                    }
                SettingsView()
                    .tabItem {
                        Label("More", systemImage: "gearshape.fill")
                    }
            }
        }
        .tint(Color.blue) // Highlight the selected tab in blue
        .accentColor(Color.gray) // Non-selected tabs are dark grey
    }
}
