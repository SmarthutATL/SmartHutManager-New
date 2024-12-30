import SwiftUI
import CoreData

struct ManageInventoryView: View {
    let context: NSManagedObjectContext
    var body: some View {
        VStack {
            Text("Manage Inventory")
                .font(.largeTitle)
                .padding()
            
            Text("This is where you can manage existing inventory items.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Manage Inventory")
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
    }
}
