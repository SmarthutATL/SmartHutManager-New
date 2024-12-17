import SwiftUI
import CoreData
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck

@main
struct SmartHutManagerApp: App {
    let persistenceController = PersistenceController.shared
    private var iCloudSyncManager: ICloudSyncManager

    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true

    init() {
        print("Initializing SmartHutManagerApp")

        // Initialize Firebase
        FirebaseApp.configure()
        print("Firebase configured")

        // Setup App Check
        #if DEBUG
            let providerFactory = AppCheckDebugProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
            print("Firebase App Check debug provider set")
        #else
            let providerFactory = DeviceCheckProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
            print("Firebase App Check DeviceCheck provider set")
        #endif

        // Register custom value transformers
        ValueTransformer.setValueTransformer(InvoiceItemTransformer(), forName: NSValueTransformerName("InvoiceItemTransformer"))
        ValueTransformer.setValueTransformer(MaterialItemTransformer(), forName: NSValueTransformerName("MaterialItemTransformer"))
        ValueTransformer.setValueTransformer(BadgesTransformer(), forName: NSValueTransformerName("BadgesTransformer"))
        print("Custom value transformers registered")

        // Initialize iCloudSyncManager
        iCloudSyncManager = ICloudSyncManager(persistentContainer: persistenceController.container)
        print("iCloudSyncManager initialized")

        // Seed job categories and job options
        seedData(context: persistenceController.container.viewContext)
        print("Data seeding complete")

        // Sync tradesmen data from Firestore to Core Data
        TradesmenManager.shared.syncTradesmen(context: persistenceController.container.viewContext) { error in
            if let error = error {
                print("Failed to sync tradesmen: \(error)")
            } else {
                print("Tradesmen data synced successfully from Firestore to Core Data")
            }
        }

        // Retroactively update tradesmen for completed jobs
        retroactivelyUpdateTradesmen(context: persistenceController.container.viewContext)
    }

    var body: some Scene {
            WindowGroup {
                ZStack {
                    if showSplash {
                        SplashScreenView()
                            .transition(.opacity)
                    } else {
                        MainTabView(viewContext: persistenceController.container.viewContext)
                            .environment(\.managedObjectContext, persistenceController.container.viewContext)
                            .environmentObject(authViewModel)
                    }
                }
                .onAppear {
                    // Hide the splash screen after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                        withAnimation {
                            showSplash = false
                        }
                    }
                }
                .onChange(of: scenePhase) {
                    if scenePhase == .background {
                        handleScenePhaseChange()
                    }
                }
                .preferredColorScheme(.dark)
            }
        }

        private func handleScenePhaseChange() {
            persistenceController.throttledSaveContext()
        }

    private func retroactivelyUpdateTradesmen(context: NSManagedObjectContext) {
        // Fetch all tradesmen to reset their points
        let tradesmenFetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        
        do {
            let allTradesmen = try context.fetch(tradesmenFetchRequest)
            print("Found \(allTradesmen.count) tradesmen. Resetting points to 0.")
            
            // Reset points and badges for all tradesmen
            for tradesman in allTradesmen {
                tradesman.points = 0
                tradesman.completedJobs = 0
                tradesman.badges = [] // Clear badges if needed
            }
            
            // Save the reset state before recalculating
            try context.save()
            print("All tradesmen points reset to 0.")
            
        } catch {
            print("Failed to reset tradesmen points: \(error.localizedDescription)")
            return
        }
        
        // Fetch all completed work orders
        let fetchRequest: NSFetchRequest<WorkOrder> = WorkOrder.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", "Completed")
        
        do {
            let completedWorkOrders = try context.fetch(fetchRequest)
            print("Found \(completedWorkOrders.count) completed work orders.")
            
            for workOrder in completedWorkOrders {
                if let tradesmenSet = workOrder.tradesmen as? Set<Tradesmen> {
                    for tradesman in tradesmenSet {
                        // Increment completed jobs
                        tradesman.completedJobs += 1
                        
                        // Add points
                        TradesmenManager.shared.addPoints(to: tradesman, points: 50, context: context)
                        
                        // Assign badges
                        if tradesman.completedJobs == 1 {
                            TradesmenManager.shared.earnBadge(for: tradesman, badge: "First Job Completed", context: context)
                        } else if tradesman.completedJobs % 10 == 0 {
                            TradesmenManager.shared.earnBadge(for: tradesman, badge: "10 Jobs Milestone", context: context)
                        }
                    }
                }
            }
            
            // Save the context after updates
            try context.save()
            print("Retroactive update completed successfully.")
            
        } catch {
            print("Failed to fetch or update completed work orders: \(error.localizedDescription)")
        }
    }
}

