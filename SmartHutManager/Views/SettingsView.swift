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

    @State private var selectedLogo: UIImage? = nil
    @State private var selectedPlan: String = "Basic"
    @State private var isShowingImagePicker = false
    @State private var isShowingTradesmenList = false
    @State private var isShowingInvoicesList = false
    @State private var isShowingSubscriptionPlanView = false
    @State private var authenticationFailed = false
    @State private var goldShineOffset: CGFloat = -250

    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager // Access shared manager
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true // Track dark mode state

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // General Settings Section
                    cardView {
                        NavigationLink(destination: GeneralSettingsView()) {
                            SettingsItem(icon: "gearshape.fill", title: "General", color: .yellow)
                                .foregroundColor(isDarkMode ? .white : .black) // Adjust text color
                        }
                    }

                    // Tradesman Account Section
                    cardView {
                        NavigationLink(destination: TradesmanAccountSection(tradesman: adminTradesmen.first)) {
                            SettingsItem(icon: "person.crop.circle.fill", title: "Account Details", color: .blue)
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }

                    // Recently Deleted Section
                    cardView {
                        NavigationLink(destination: RecentlyDeletedItemsView()) {
                            SettingsItem(icon: "trash.fill", title: "Recently Deleted Items", color: .red)
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }

                    // Subscription Plan Section
                    cardView(isGold: true) {
                        Button(action: {
                            isShowingSubscriptionPlanView.toggle()
                        }) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 32, height: 32)
                                Text("Subscription Plan")
                                    .font(.body)
                                    .foregroundColor(isDarkMode ? .white : .black)
                                Spacer()
                                Text(selectedPlan)
                                    .foregroundColor(.black)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    // Custom Branding Section
                    cardView(isGold: true) {
                        NavigationLink(destination: CustomBrandingView()) {
                            SettingsItem(icon: "paintbrush.fill", title: "Custom Branding", color: .purple)
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }

                    // Invoices Section (Face ID Authentication)
                    cardView {
                        Button(action: {
                            authenticateUser(for: .manageInvoices)
                        }) {
                            HStack {
                                SettingsItem(icon: "doc.plaintext", title: "Manage Invoices", color: .blue)
                                    .foregroundColor(isDarkMode ? .white : .black)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .sheet(isPresented: $isShowingInvoicesList) {
                        InvoiceListView(viewContext: viewContext)
                    }

                    // Technician Management Section (Face ID Authentication)
                    cardView(isGold: true) {
                        Button(action: {
                            authenticateUser(for: .manageTechnicians)
                        }) {
                            HStack {
                                SettingsItem(icon: "person.2.fill", title: "Manage Technicians", color: .blue)
                                    .foregroundColor(isDarkMode ? .white : .black)
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .sheet(isPresented: $isShowingTradesmenList) {
                        TradesmenListView()
                    }

                    // Technician Performance Section
                    cardView(isGold: true) {
                        NavigationLink(destination: TechnicianPerformanceView()) {
                            SettingsItem(icon: "chart.bar.fill", title: "Technician Performance", color: .orange)
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }

                    // Manage Job Categories Section
                    cardView {
                        NavigationLink(destination: ManageJobCategoriesView()) {
                            SettingsItem(icon: "folder.fill", title: "Manage Job Categories", color: .orange)
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }

                    // Manage Payment Methods Section
                    cardView {
                        NavigationLink(destination: Text("Manage Payment Methods")) {
                            SettingsItem(icon: "creditcard.fill", title: "Manage Payment Methods", color: .green)
                                .foregroundColor(isDarkMode ? .white : .black)
                        }
                    }

                    // Notification Settings Section
                    cardView {
                        NavigationLink(destination: NotificationSettingsView()) {
                            SettingsItem(icon: "bell.fill", title: "Notification Settings", color: .blue)
                                .foregroundColor(isDarkMode ? .white : .black)
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
    private func cardView<Content: View>(
        isGold: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            // Background for normal or gold cards
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: isGold
                        ? Gradient(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)])
                        : Gradient(colors: [Color(.secondarySystemBackground), Color(.secondarySystemBackground)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Shine effect for gold cards
            if isGold {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 400, height: 60) // Adjust width to match card size
                    .offset(x: goldShineOffset) // Dynamic offset for shine
                    .mask(
                        VStack(alignment: .leading, spacing: 12) {
                            content()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    )
            }
            
            // Lock Icon Overlay for Gold Cards
            if isGold {
                VStack {
                    HStack {
                        Spacer()
                            .frame(maxWidth: 170) // Add padding to move the lock icon left
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            if isGold {
                startGoldShineAnimation() // Start shine animation for gold cards
            }
        }
    }
    
    private func startGoldShineAnimation() {
        withAnimation(
            Animation.linear(duration: 4.0)
                .repeatForever(autoreverses: true)
        ) {
            goldShineOffset = 250 // Adjust for smooth animation across the card
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
