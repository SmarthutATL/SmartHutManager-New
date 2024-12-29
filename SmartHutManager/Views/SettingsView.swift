import SwiftUI
import LocalAuthentication
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
    @State private var isShowingTradesmenList = false
    @State private var isShowingInvoicesList = false
    @State private var isShowingSubscriptionPlanView = false
    @State private var authenticationFailed = false

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // General Settings Section
                    cardView {
                        NavigationLink(destination: GeneralSettingsView()) {
                            SettingsItem(icon: "gearshape.fill", title: "General Settings", color: .yellow)
                                .foregroundColor(.white)
                        }
                    }

                    // Tradesman Account Section
                    cardView {
                        NavigationLink(destination: TradesmanAccountSection(tradesman: adminTradesmen.first)) {
                            SettingsItem(icon: "person.crop.circle.fill", title: "Account Details", color: .blue)
                                .foregroundColor(.white)
                        }
                    }

                    // Recently Deleted Section
                    cardView {
                        SettingsItem(icon: "trash.fill", title: "Recently Deleted Items", color: .red)
                            .foregroundColor(.white)
                    }

                    // Subscription Plan Section
                    cardView {
                        Button(action: {
                            isShowingSubscriptionPlanView.toggle()
                        }) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 32, height: 32)
                                Text("Subscription Plan")
                                    .font(.body)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(selectedPlan)
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    // Customize Logo Section
                    cardView {
                        SettingsItem(icon: "photo.fill", title: "Customize Logo", color: .purple)
                            .foregroundColor(.white)
                            .onTapGesture {
                                isShowingImagePicker.toggle()
                            }
                    }

                    // Invoices Section (Face ID Authentication)
                    cardView {
                        Button(action: {
                            authenticateUser(for: .manageInvoices)
                        }) {
                            HStack {
                                SettingsItem(icon: "doc.plaintext", title: "Manage Invoices", color: .blue)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .sheet(isPresented: $isShowingInvoicesList) {
                        InvoiceListView(viewContext: viewContext)
                    }

                    // Technician Management Section (Face ID Authentication)
                    cardView {
                        Button(action: {
                            authenticateUser(for: .manageTechnicians)
                        }) {
                            HStack {
                                SettingsItem(icon: "person.2.fill", title: "Manage Technicians", color: .blue)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .sheet(isPresented: $isShowingTradesmenList) {
                        TradesmenListView()
                    }

                    // Technician Performance Section
                    cardView {
                        NavigationLink(destination: TechnicianPerformanceView()) {
                            SettingsItem(icon: "chart.bar.fill", title: "Technician Performance", color: .orange)
                                .foregroundColor(.white)
                        }
                    }

                    // Manage Job Categories Section
                    cardView {
                        NavigationLink(destination: ManageJobCategoriesView()) {
                            SettingsItem(icon: "folder.fill", title: "Manage Job Categories", color: .orange)
                                .foregroundColor(.white)
                        }
                    }

                    // Manage Payment Methods Section
                    cardView {
                        NavigationLink(destination: Text("Manage Payment Methods")) {
                            SettingsItem(icon: "creditcard.fill", title: "Manage Payment Methods", color: .green)
                                .foregroundColor(.white)
                        }
                    }

                    // Notification Settings Section
                    cardView {
                        NavigationLink(destination: NotificationSettingsView()) {
                            SettingsItem(icon: "bell.fill", title: "Notification Settings", color: .blue)
                                .foregroundColor(.white)
                        }
                    }

                    // Sign Out Section
                    cardView {
                        signOutSection()
                    }
                }
                .padding(.horizontal, 16)
                .navigationTitle("Settings")
                .sheet(isPresented: $isShowingImagePicker) {
                    ImagePicker(selectedImage: $selectedLogo)
                }
                .sheet(isPresented: $isShowingSubscriptionPlanView) {
                    SubscriptionPlanView(
                        selectedPlan: $selectedPlan,
                        updatePlanInFirebase: updatePlanInFirebase
                    )
                }
                .onAppear {
                    fetchCurrentPlan()
                }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }

    // MARK: - Face ID / Passcode Authentication
    enum AuthenticationPurpose {
        case manageTechnicians
        case manageInvoices
    }

    private func authenticateUser(for purpose: AuthenticationPurpose) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to \(purpose == .manageTechnicians ? "manage technicians" : "manage invoices")"

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        switch purpose {
                        case .manageTechnicians:
                            isShowingTradesmenList = true
                        case .manageInvoices:
                            isShowingInvoicesList = true
                        }
                    } else {
                        authenticationFailed = true
                    }
                }
            }
        } else {
            print("Face ID / Passcode not available.")
        }
    }

    // Reusable card-style container
    private func cardView<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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

    private func signOutSection() -> some View {
        VStack {
            Button(action: {
                authViewModel.signOut()
            }) {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Color.red)
                .cornerRadius(8)
            }
        }
    }
}
