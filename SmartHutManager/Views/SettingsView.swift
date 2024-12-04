import SwiftUI
import CoreData
import FirebaseAuth

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

    @State private var isShowingTradesmenList = false
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            List {
                // Tradesman's Account Info
                Section {
                    if let admin = adminTradesmen.first {
                        TradesmanAccountSection(tradesman: admin)
                    } else {
                        Text("No tradesman available")
                            .foregroundColor(.gray)
                    }
                }

                // Recently Deleted Section
                Section(header: Text("Recently Deleted")) {
                    if recentlyDeletedItems.isEmpty {
                        Text("No recently deleted items")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(recentlyDeletedItems) { item in
                            HStack {
                                Image(systemName: item.icon)
                                    .foregroundColor(item.type == .invoice ? .green : .blue)
                                Text(item.description)
                                Spacer()
                                Button(action: { restoreItem(item) }) {
                                    Text("Restore")
                                        .foregroundColor(.blue)
                                }
                                Button(action: { deleteItemPermanently(item) }) {
                                    Text("Delete")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }

                // App Management Section for Admin Controls
                Section(header: Text("App Management")) {
                    SettingsItem(icon: "folder.fill", title: "Manage Job Categories", color: .orange)
                    SettingsItem(icon: "creditcard.fill", title: "Manage Payment Methods", color: .green)
                    SettingsItem(icon: "bell.fill", title: "Notification Settings", color: .blue)
                }

                // Tradesmen Management Section
                Section(header: Text("Technician Management")) {
                    Button(action: {
                        isShowingTradesmenList.toggle()
                    }) {
                        SettingsItem(icon: "person.crop.circle.fill", title: "Manage Technicians", color: .blue)
                    }
                }

                // App Info & Support Section
                Section(header: Text("App Info & Support")) {
                    SettingsItem(icon: "gearshape", title: "App Version: 1.0.0", color: .gray)
                    SettingsItem(icon: "questionmark.circle.fill", title: "Contact Support", color: .blue)
                }

                // Sign Out Section
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingTradesmenList) {
                TradesmenListView()
            }
        }
    }

    private func restoreItem(_ item: DeletedItem) {
        recentlyDeletedItems.removeAll { $0.id == item.id }
    }

    private func deleteItemPermanently(_ item: DeletedItem) {
        recentlyDeletedItems.removeAll { $0.id == item.id }
    }
}

// MARK: - Tradesmen List View
struct TradesmenListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Tradesmen.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)]
    ) var tradesmen: FetchedResults<Tradesmen>

    @State private var isShowingCreateTradesman = false

    var body: some View {
        NavigationView {
            List {
                ForEach(tradesmen) { tradesman in
                    NavigationLink(destination: EditTradesmanView(tradesman: tradesman)) {
                        VStack(alignment: .leading) {
                            Text(tradesman.name ?? "Unknown")
                                .font(.headline)
                            Text(tradesman.jobTitle ?? "Unknown Job Title")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            if let phone = tradesman.phoneNumber, !phone.isEmpty {
                                Text("Phone: \(phone)")
                            }
                            if let address = tradesman.address, !address.isEmpty {
                                Text("Address: \(address)")
                            }
                        }
                    }
                }
                .onDelete(perform: deleteTradesman)
            }
            .navigationTitle("Tradesmen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingCreateTradesman.toggle() }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingCreateTradesman) {
                CreateTradesmanView()
            }
            .onAppear {
                TradesmenManager.shared.syncTradesmen(context: viewContext) { error in
                    if let error = error {
                        print("Failed to sync tradesmen: \(error)")
                    } else {
                        print("Tradesmen data synced successfully from Firestore to Core Data")
                    }
                }
            }
        }
    }

    private func deleteTradesman(at offsets: IndexSet) {
        offsets.map { tradesmen[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete tradesman: \(error.localizedDescription)")
        }
    }
}

// MARK: - Create Tradesman View
struct CreateTradesmanView: View {
    @State private var name = ""
    @State private var jobTitle = ""
    @State private var phoneNumber = ""
    @State private var address = ""
    @State private var email = ""

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tradesman Info")) {
                    TextField("Full Name", text: $name)
                    TextField("Job Title", text: $jobTitle)
                    TextField("Phone Number", text: $phoneNumber)
                    TextField("Address", text: $address)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Button("Create Tradesman") {
                    let newTradesman = Tradesmen(context: viewContext)
                    newTradesman.name = name
                    newTradesman.jobTitle = jobTitle
                    newTradesman.phoneNumber = phoneNumber
                    newTradesman.address = address
                    newTradesman.email = email

                    do {
                        try viewContext.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("Failed to save tradesman: \(error.localizedDescription)")
                    }
                }
                .disabled(name.isEmpty || jobTitle.isEmpty || phoneNumber.isEmpty || address.isEmpty || email.isEmpty)
            }
            .navigationTitle("Create Tradesman")
        }
    }
}

// MARK: - Edit Tradesman View
struct EditTradesmanView: View {
    @ObservedObject var tradesman: Tradesmen

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Tradesman Info")) {
                    TextField("Full Name", text: Binding(
                        get: { tradesman.name ?? "" },
                        set: { tradesman.name = $0 }
                    ))
                    TextField("Job Title", text: Binding(
                        get: { tradesman.jobTitle ?? "" },
                        set: { tradesman.jobTitle = $0 }
                    ))
                    TextField("Phone Number", text: Binding(
                        get: { tradesman.phoneNumber ?? "" },
                        set: { tradesman.phoneNumber = $0 }
                    ))
                    TextField("Address", text: Binding(
                        get: { tradesman.address ?? "" },
                        set: { tradesman.address = $0 }
                    ))
                    TextField("Email", text: Binding(
                        get: { tradesman.email ?? "" },
                        set: { tradesman.email = $0 }
                    ))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                }

                Button("Save Changes") {
                    do {
                        if viewContext.hasChanges {
                            try viewContext.save()
                        }
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("Failed to save tradesman: \(error.localizedDescription)")
                    }
                }
                .disabled(tradesman.name?.isEmpty ?? true || tradesman.jobTitle?.isEmpty ?? true || tradesman.phoneNumber?.isEmpty ?? true || tradesman.address?.isEmpty ?? true || tradesman.email?.isEmpty ?? true)
            }
            .navigationTitle("Edit Tradesman")
        }
    }
}

// MARK: - Tradesman Account Section
struct TradesmanAccountSection: View {
    let tradesman: Tradesmen

    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray)
                .frame(width: 50, height: 50)
                .overlay(Text("DO").foregroundColor(.white))

            VStack(alignment: .leading) {
                Text(tradesman.name ?? "Unknown")
                    .font(.headline)
                Text(tradesman.jobTitle ?? "Unknown Job Title")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Phone: \(tradesman.phoneNumber ?? "N/A")")
                Text("Address: \(tradesman.address ?? "N/A")")
            }
        }
    }
}

// MARK: - DeletedItem Enum and Data Model
enum DeletedItemType {
    case invoice
    case workOrder
}

struct DeletedItem: Identifiable {
    var id = UUID()
    var type: DeletedItemType
    var description: String

    var icon: String {
        switch type {
        case .invoice: return "doc.text.fill"
        case .workOrder: return "wrench.and.screwdriver.fill"
        }
    }
}

// MARK: - SettingsItem Reused View
struct SettingsItem: View {
    var icon: String
    var title: String
    var color: Color
    var toggle: Bool = false
    @State private var isOn: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
            Text(title)
                .font(.body)
            Spacer()

            if toggle {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .opacity(toggle ? 0 : 1)
        }
    }
}
