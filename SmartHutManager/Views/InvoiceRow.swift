import SwiftUI

struct InvoiceRow: View {
    @ObservedObject var invoice: Invoice
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                // Customer Name and Job Category
                Text(invoice.workOrder?.customer?.name ?? "Unknown Customer")
                    .font(.headline)
                
                if let category = invoice.workOrder?.category {
                    Text("Job: \(category)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Status: Paid/Unpaid
                Text(invoice.status ?? "Unpaid")
                    .font(.subheadline)
                    .foregroundColor(invoice.status == "Paid" ? .green : .red)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                // Invoice Number
                Text("#\(invoice.invoiceNumber)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Total Amount
                Text("$\(invoice.computedTotalAmount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 6)
    }
}
