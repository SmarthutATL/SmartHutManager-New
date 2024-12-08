import SwiftUI
import CoreData
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @FetchRequest(
        entity: Tradesmen.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "name == %@", "Darius Ogletree")
    ) var adminTradesmen: FetchedResults<Tradesmen>

    @State private var recentlyDeletedItems: [DeletedItem] = [
        DeletedItem(type: .invoice, description: "Invoice #1234"),
        DeletedItem(type: .workOrder, description: "Work Order #5678")
    ]
    @State private var selectedLogo: UIImage? = nil
    @State private var selectedPlan: String = "Basic"
    @State private var isShowingImagePicker = false
    @State private var isShowingTradesmenList = false // Added this
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            List {
                // Tradesman Account Section
                TradesmanAccountSection(tradesman: adminTradesmen.first)

                // Recently Deleted Section
                RecentlyDeletedSection(items: $recentlyDeletedItems)

                // Subscription Plan Section
                SubscriptionPlanView(
                    selectedPlan: $selectedPlan,
                    updatePlanInFirebase: updatePlanInFirebase
                )

                // Customize Logo Section
                CustomizeLogoSection(
                    selectedLogo: $selectedLogo,
                    isShowingImagePicker: $isShowingImagePicker
                )

                // Technician Management Section
                Section(header: Text("Technician Management")) {
                    Button(action: {
                        isShowingTradesmenList.toggle()
                    }) {
                        SettingsItem(icon: "person.crop.circle.fill", title: "Manage Technicians", color: .blue)
                    }
                }

                // App Management Section
                appManagementSection()

                // Sign Out Section
                signOutSection()
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedLogo)
            }
            .sheet(isPresented: $isShowingTradesmenList) {
                TradesmenListView() // Presents the TradesmenListView
            }
            .onAppear {
                fetchCurrentPlan()
            }
        }
    }

    private func fetchCurrentPlan() {
        guard let email = authViewModel.currentUserEmail else { return }
        let db = Firestore.firestore()
        db.collection("users").document(email).getDocument { snapshot, error in
            if let data = snapshot?.data(), let plan = data["subscriptionPlan"] as? String {
                DispatchQueue.main.async { self.selectedPlan = plan }
            }
        }
    }

    private func updatePlanInFirebase(_ plan: String) {
        guard let email = authViewModel.currentUserEmail else { return }
        let db = Firestore.firestore()
        db.collection("users").document(email).updateData(["subscriptionPlan": plan])
    }

    private func appManagementSection() -> some View {
        Section(header: Text("App Management")) {
            SettingsItem(icon: "folder.fill", title: "Manage Job Categories", color: .orange)
            SettingsItem(icon: "creditcard.fill", title: "Manage Payment Methods", color: .green)
            SettingsItem(icon: "bell.fill", title: "Notification Settings", color: .blue)
        }
    }

    private func signOutSection() -> some View {
        Section {
            Button(action: {
                authViewModel.signOut()
            }) {
                Text("Sign Out")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
