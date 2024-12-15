import SwiftUI
import CoreData

struct TradesmenListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: Tradesmen.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)]
    ) var tradesmen: FetchedResults<Tradesmen>

    @State private var isShowingCreateTradesman = false
    @State private var isShowingEditTradesman = false
    @State private var selectedTradesman: Tradesmen?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(tradesmen) { tradesman in
                        TradesmanCardView(tradesman: tradesman, onEdit: {
                            // Set selectedTradesman and present the sheet synchronously
                            self.selectedTradesman = tradesman
                            self.isShowingEditTradesman = true
                        })
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
            .sheet(item: $selectedTradesman) { tradesman in
                EditTradesmanView(tradesman: tradesman)
                    .onDisappear {
                        selectedTradesman = nil // Reset to avoid conflicts
                    }
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
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

// MARK: - TradesmanCardView
struct TradesmanCardView: View {
    let tradesman: Tradesmen
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(tradesman.name ?? "Unknown")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    onEdit()
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            if let jobTitle = tradesman.jobTitle, !jobTitle.isEmpty {
                Text(jobTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            if let phone = tradesman.phoneNumber, !phone.isEmpty {
                Button(action: {
                    if let url = URL(string: "tel://\(phone)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green)
                        Text(phone)
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
            }
            if let email = tradesman.email, !email.isEmpty {
                Button(action: {
                    if let url = URL(string: "mailto:\(email)"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.orange)
                        Text(email)
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
            }
            if let address = tradesman.address, !address.isEmpty {
                Button(action: {
                    if let url = URL(string: "http://maps.apple.com/?q=\(address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.red)
                        Text(address)
                            .foregroundColor(.blue)
                            .underline()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
