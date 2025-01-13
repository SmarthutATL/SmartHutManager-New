import SwiftUI
import CoreData

struct TradesmenListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var tradesmen: [Tradesmen] = []
    @State private var isLoading = true
    @State private var isShowingCreateTradesman = false
    @State private var selectedEditTradesman: Tradesmen?
    @State private var selectedDetailTradesman: Tradesmen?
    @State private var selectedDeleteTradesman: Tradesmen? // For tracking the tradesman to delete
    @State private var isShowingDeleteConfirmation = false // For showing the delete confirmation

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading technicians...")
                        .padding()
                } else if tradesmen.isEmpty {
                    Text("No technicians available.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
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
                                    },
                                    onDelete: {
                                        self.selectedDeleteTradesman = tradesman
                                        self.isShowingDeleteConfirmation = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                }
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
            .sheet(isPresented: $isShowingCreateTradesman) {
                CreateTradesmanView()
                    .onDisappear {
                        loadTradesmen()
                    }
            }
            .sheet(item: $selectedEditTradesman) { tradesman in
                EditTradesmanView(tradesman: tradesman)
                    .onDisappear {
                        selectedEditTradesman = nil
                        loadTradesmen()
                    }
            }
            .sheet(item: $selectedDetailTradesman) { tradesman in
                TechDetailView(tradesman: tradesman)
                    .onDisappear {
                        selectedDetailTradesman = nil
                    }
            }
            .confirmationDialog(
                "Are you sure you want to delete this technician? This action cannot be undone.",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let tradesmanToDelete = selectedDeleteTradesman {
                        deleteTradesman(tradesmanToDelete)
                    }
                }
                Button("Cancel", role: .cancel) {
                    selectedDeleteTradesman = nil // Reset the selection
                }
            }
            .onAppear {
                loadTradesmen()
            }
        }
    }

    private func deleteTradesman(_ tradesman: Tradesmen) {
        isLoading = true
        TradesmenManager.shared.deleteTradesman(tradesman, context: viewContext) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    loadTradesmen() // Refresh the list after deletion
                } else {
                    print("Failed to delete tradesman.")
                }
            }
        }
    }

    private func loadTradesmen() {
        isLoading = true
        TradesmenManager.shared.assignMissingIds(context: viewContext)
        TradesmenManager.shared.fetchTradesmen(context: viewContext) { fetchedTradesmen in
            DispatchQueue.main.async {
                self.tradesmen = fetchedTradesmen
                self.isLoading = false
            }
        }
    }
}

// MARK: - TradesmanCardView
struct TradesmanCardView: View {
    let tradesman: Tradesmen
    let onEdit: () -> Void
    let onDetails: () -> Void
    let onDelete: () -> Void // Add a delete callback

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
                Button(action: {
                    onDelete() // Trigger delete action
                }) {
                    Image(systemName: "trash.fill")
                        .font(.title3)
                        .foregroundColor(.red)
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
