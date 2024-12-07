import SwiftUI
import CoreData

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
            .navigationTitle("Techs")
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
