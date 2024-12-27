import SwiftUI
import CoreData
import FirebaseFirestore

struct TradesmenListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    private let db = Firestore.firestore()

    @FetchRequest(
        entity: Tradesmen.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)]
    ) var tradesmen: FetchedResults<Tradesmen>

    @State private var isShowingCreateTradesman = false
    @State private var selectedEditTradesman: Tradesmen?
    @State private var selectedDetailTradesman: Tradesmen?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(tradesmen) { tradesman in
                        TradesmanCardView(
                            tradesman: tradesman,
                            onEdit: {
                                self.selectedEditTradesman = tradesman
                            },
                            onDetails: {
                                self.selectedDetailTradesman = tradesman
                            }
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Technicians")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingCreateTradesman.toggle() }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            // Create Tradesman Sheet
            .sheet(isPresented: $isShowingCreateTradesman) {
                CreateTradesmanView()
            }
            // Edit Tradesman Sheet
            .sheet(item: $selectedEditTradesman) { tradesman in
                EditTradesmanView(tradesman: tradesman)
                    .onDisappear {
                        selectedEditTradesman = nil // Reset to avoid conflicts
                    }
            }
            // Technician Detail Sheet
            .sheet(item: $selectedDetailTradesman) { tradesman in
                TechDetailView(tradesman: tradesman)
                    .onDisappear {
                        selectedDetailTradesman = nil
                    }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }

    private func deleteTradesman(at offsets: IndexSet) {
        offsets.map { tradesmen[$0] }.forEach { tradesman in
            // Delete from CoreData
            viewContext.delete(tradesman)

            // Delete from Firestore
            let tradesmanId = tradesman.objectID.uriRepresentation().absoluteString
            db.collection("tradesmen").document(tradesmanId).delete { error in
                if let error = error {
                    print("Failed to delete tradesman from Firestore: \(error.localizedDescription)")
                } else {
                    print("Tradesman successfully deleted from Firestore.")
                }
            }
        }

        // Save CoreData changes
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete tradesman: \(error.localizedDescription)")
        }
    }
}

// MARK: - TradesmanCardView
struct TradesmanCardView: View {
    let tradesman: Tradesmen
    let onEdit: () -> Void
    let onDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tradesman.name ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let jobTitle = tradesman.jobTitle, !jobTitle.isEmpty {
                        Text(jobTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: {
                    onEdit()
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }

            HStack(spacing: 20) {
                if let phone = tradesman.phoneNumber, !phone.isEmpty {
                    Button(action: {
                        if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }

                if let email = tradesman.email, !email.isEmpty {
                    Button(action: {
                        if let url = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                    }
                }

                if let address = tradesman.address, !address.isEmpty {
                    Button(action: {
                        if let url = URL(string: "http://maps.apple.com/?q=\(address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"), UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "map.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onDetails()
        }
    }
}
