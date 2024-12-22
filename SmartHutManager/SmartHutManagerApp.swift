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
                    ContentView()
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
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background {
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
        // Implementation remains the same
    }
}
