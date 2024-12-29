import SwiftUI

struct InventoryReportsView: View {
    var body: some View {
        VStack {
            Text("Inventory Reports")
                .font(.largeTitle)
                .padding()
            
            Text("This is where you can generate and view inventory reports.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Reports")
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
    }
}