import SwiftUI

struct AddInventoryView: View {
    var body: some View {
        VStack {
            Text("Add Inventory")
                .font(.largeTitle)
                .padding()
            
            Text("This is where you can add new items to your inventory.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Add Inventory")
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
    }
}
