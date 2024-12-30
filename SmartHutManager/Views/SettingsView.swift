import SwiftUI
import LocalAuthentication
import CoreData
import FirebaseAuth
import FirebaseFirestore


enum AuthenticationPurpose {
    case manageInvoices
    case manageTechnicians
}

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
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // General Settings Section
                    generalSettingsSection()
                    
                    // Tradesman Account Section
                    tradesmanAccountSection()
                    
                    // Recently Deleted Section
                    recentlyDeletedSection()
                    
                    // Subscription Plan Section
                    subscriptionPlanSection()
                    
                    // Custom Branding Section
                    customBrandingSection()
                    
                    // Inventory Management Section
                    inventoryManagementSection()
                    
                    // Invoices Section (Face ID Authentication)
                    invoicesSection()
                    
                    // Technician Management Section (Face ID Authentication)
                    technicianManagementSection()
                    
                    // Technician Performance Section
                    technicianPerformanceSection()
                    
                    // Manage Job Categories Section
                    manageJobCategoriesSection()
                    
                    // Manage Payment Methods Section
                    managePaymentMethodsSection()
                    
                    // Notification Settings Section
                    notificationSettingsSection()
                    
                    // Sign Out Section
                    signOutSection()
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
    
    // MARK: - Settings Sections
    private func generalSettingsSection() -> some View {
        cardView {
            NavigationLink(destination: GeneralSettingsView()) {
                SettingsItem(icon: "gearshape.fill", title: "General", color: .yellow)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
    
    private func tradesmanAccountSection() -> some View {
        cardView {
            NavigationLink(destination: TradesmanAccountSection(tradesman: adminTradesmen.first)) {
                SettingsItem(icon: "person.crop.circle.fill", title: "Account Details", color: .blue)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
    
    private func recentlyDeletedSection() -> some View {
        cardView {
            NavigationLink(destination: RecentlyDeletedItemsView()) {
                SettingsItem(icon: "trash.fill", title: "Recently Deleted Items", color: .red)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
    
    private func subscriptionPlanSection() -> some View {
        cardView(isGold: true) {
            Button(action: {
                isShowingSubscriptionPlanView.toggle()
            }) {
                HStack {
                    SettingsItem(icon: "creditcard.fill", title: "Subscription Plan", color: .green)
                        .foregroundColor(isDarkMode ? .white : .black)
                }
            }
        }
    }
    
    private func customBrandingSection() -> some View {
        cardView(isGold: true) {
            NavigationLink(destination: CustomBrandingView()) {
                SettingsItem(icon: "paintbrush.fill", title: "Custom Branding", color: .purple)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
    
    private func inventoryManagementSection() -> some View {
        cardView {
            NavigationLink(destination: InventoryManagementView()) {
                SettingsItem(icon: "archivebox.fill", title: "Manage Inventory", color: .green)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
    
    private func invoicesSection() -> some View {
        cardView {
            Button(action: {
                authenticateUser(for: .manageInvoices)
            }) {
                SettingsItem(icon: "doc.plaintext", title: "Manage Invoices", color: .blue)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
        .sheet(isPresented: $isShowingInvoicesList) {
            InvoiceListView(viewContext: viewContext)
        }
    }
    
    private func technicianManagementSection() -> some View {
        cardView(isGold: true) {
            Button(action: {
                authenticateUser(for: .manageTechnicians)
            }) {
                SettingsItem(icon: "person.2.fill", title: "Manage Technicians", color: .blue)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
        .sheet(isPresented: $isShowingTradesmenList) {
            TradesmenListView()
        }
    }
    
    private func technicianPerformanceSection() -> some View {
        cardView(isGold: true) {
            NavigationLink(destination: TechnicianPerformanceView()) {
                SettingsItem(icon: "chart.bar.fill", title: "Technician Performance", color: .orange)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
    
    private func manageJobCategoriesSection() -> some View {
        cardView {
            NavigationLink(destination: ManageJobCategoriesView()) {
                SettingsItem(icon: "folder.fill", title: "Manage Job Categories", color: .orange)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
    
    private func managePaymentMethodsSection() -> some View {
        cardView {
            NavigationLink(destination: ManagePaymentsView()) {
                SettingsItem(icon: "creditcard.fill", title: "Manage Payment Methods", color: .green)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
    
    private func notificationSettingsSection() -> some View {
        cardView {
            NavigationLink(destination: NotificationSettingsView()) {
                SettingsItem(icon: "bell.fill", title: "Notification Settings", color: .blue)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
    }
    
    private func signOutSection() -> some View {
        cardView {
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
    
    // MARK: - Supporting Methods
    private func authenticateUser(for purpose: AuthenticationPurpose) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to \(purpose == .manageTechnicians ? "manage technicians" : "manage invoices")"
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
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
    
    private func fetchCurrentPlan() {
        guard let email = authViewModel.currentUserEmail else {
            print("Error: No authenticated user email.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                return
            }

            if let document = querySnapshot?.documents.first {
                if let plan = document.data()["subscriptionPlan"] as? String {
                    DispatchQueue.main.async {
                        self.selectedPlan = plan
                    }
                } else {
                    print("Subscription plan not found.")
                }
            } else {
                print("User document not found.")
            }
        }
    }
    
    private func updatePlanInFirebase(_ plan: String) {
        guard let email = authViewModel.currentUserEmail else { return }
        let db = Firestore.firestore()
        db.collection("users").document(email).updateData(["subscriptionPlan": plan])
    }
    
    private func cardView<Content: View>(
        isGold: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        ZStack {
            VStack {
                content()
            }
            .padding()
            .background(
                Group {
                    if isGold {
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(.secondarySystemBackground)
                    }
                }
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
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
                    .frame(width: 400, height: 60)
                    .offset(x: goldShineOffset) // Use `goldShineOffset` for animation
                    .mask(
                        VStack {
                            content()
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    )
            }
        }
        .onAppear {
            if isGold {
                startShineAnimation() // Start animation for gold cards
            }
        }
    }

    private func startShineAnimation() {
        withAnimation(
            Animation.linear(duration: 4.0)
                .repeatForever(autoreverses: true)
        ) {
            goldShineOffset = 250 // Adjust the offset to fit the shine movement
        }
    }
}
