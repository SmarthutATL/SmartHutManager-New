
import SwiftUI
import CoreData

// MARK: - MainTabView (Main tabs after signing in)
struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)])
    var tradesmen: FetchedResults<Tradesmen>
    
    let viewContext: NSManagedObjectContext // Add this line
    
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
                InvoiceListView(viewContext: viewContext) // Pass the viewContext
                    .tabItem {
                        Label("Invoices", systemImage: "doc.plaintext")
                    }
                // Tech Tab - Filter tradesmen by signed-in email
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
                SettingsView()
                    .tabItem {
                        Label("More", systemImage: "gearshape.fill")
                    }
            }
        }
    }
}
