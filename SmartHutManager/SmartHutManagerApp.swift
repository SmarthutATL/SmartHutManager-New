import SwiftUI
import CoreData
import FirebaseCore
import FirebaseAuth
import FirebaseAppCheck
import FirebaseMessaging
import FirebaseInAppMessaging
import UserNotifications
import FirebaseAnalytics

@main
struct SmartHutManagerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    private var iCloudSyncManager: ICloudSyncManager

    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true // Appearance preference

    init() {
        print("Initializing SmartHutManagerApp")

        // Configure Firebase
        FirebaseApp.configure()
        print("Firebase configured")

        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("Firebase App Check debug provider set")
        #else
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        print("Firebase App Check DeviceCheck provider set")
        #endif

        ValueTransformer.setValueTransformer(InvoiceItemTransformer(), forName: NSValueTransformerName("InvoiceItemTransformer"))
        ValueTransformer.setValueTransformer(MaterialItemTransformer(), forName: NSValueTransformerName("MaterialItemTransformer"))
        ValueTransformer.setValueTransformer(BadgesTransformer(), forName: NSValueTransformerName("BadgesTransformer"))
        print("Custom value transformers registered")

        iCloudSyncManager = ICloudSyncManager(persistentContainer: persistenceController.container)
        print("iCloudSyncManager initialized")

        // Log a Firebase Analytics test event
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)
        print("Logged App Open event to Firebase Analytics")

        seedData(context: persistenceController.container.viewContext)
        print("Data seeding complete")

        TradesmenManager.shared.syncTradesmen(context: persistenceController.container.viewContext) { error in
            if let error = error {
                print("Failed to sync tradesmen: \(error)")
            } else {
                print("Tradesmen data synced successfully from Firestore to Core Data")
            }
        }

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
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    withAnimation {
                        showSplash = false
                    }
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background {
                    handleScenePhaseChange()
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light) // Apply appearance preference
        }
    }

    private func handleScenePhaseChange() {
        persistenceController.throttledSaveContext()
    }

    private func retroactivelyUpdateTradesmen(context: NSManagedObjectContext) {
        // Implementation remains the same
    }
}
