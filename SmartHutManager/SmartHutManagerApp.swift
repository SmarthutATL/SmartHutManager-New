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

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var deletedItemsManager = DeletedItemsManager() // Shared manager
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSplash = true
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true // Appearance preference
    @StateObject private var alertViewModel: AlertViewModel

    init() {
        print("Initializing SmartHutManagerApp")

        let context = PersistenceController.shared.container.viewContext
        _alertViewModel = StateObject(wrappedValue: AlertViewModel(context: context))
        
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
                        .onAppear {
                            handleSplashTransition()
                        }
                } else {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(authViewModel) // Provide AuthViewModel
                        .environmentObject(deletedItemsManager) // Provide DeletedItemsManager
                        .environmentObject(alertViewModel)
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

    private func handleSplashTransition() {
        if authViewModel.isUserSignedIn {
            // Skip splash screen faster if user is signed in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
        } else {
            // Show splash screen briefly before navigating to sign-in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }

    private func handleScenePhaseChange() {
        persistenceController.throttledSaveContext()
    }

    private func retroactivelyUpdateTradesmen(context: NSManagedObjectContext) {
        // Implementation remains the same
    }
}
