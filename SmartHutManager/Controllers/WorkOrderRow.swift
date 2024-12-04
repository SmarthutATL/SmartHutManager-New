import SwiftUI

struct WorkOrderRow: View {
    var workOrder: WorkOrder
    
    var body: some View {
        VStack(alignment: .leading) {
            // Safely unwrap the category and date
            Text("\(workOrder.category ?? "Unknown Category") - \(formattedDate(workOrder.date))")
                .font(.headline)
            
            // Safely unwrap the description
            Text(workOrder.workOrderDescription ?? "No Description") // Assuming workOrderDescription is the correct field name
                .font(.subheadline)
            
            // Safely unwrap and compare the status
            Text("Status: \(workOrder.status == "Completed" ? "Completed" : "Current")")
                .font(.caption)
            
            // Safely unwrap the photos
            if let photos = workOrder.photos as? [String], !photos.isEmpty {
                // Display photos in a grid view
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                    ForEach(photos, id: \.self) { photo in
                        Image(photo) // Assuming 'photo' is a valid image name or URL
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipped()
                    }
                }
            } else {
                Text("No photos available")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // Date formatting function
    func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "No Date" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
}
