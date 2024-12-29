import SwiftUI

struct InventoryOverviewView: View {
    var body: some View {
        VStack {
            Text("Inventory Overview")
                .font(.largeTitle)
                .padding()
            
            Text("This is where you can view a summary of your inventory.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Overview")
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
    }
}
