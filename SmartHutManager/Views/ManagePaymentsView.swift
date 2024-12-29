import SwiftUI
import CoreData
import PassKit

struct ManagePaymentsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var controller: InvoiceController
    @State private var selectedInvoice: Invoice? = nil
    @State private var isPaymentProcessing = false
    @State private var paymentError: String?

    init(viewContext: NSManagedObjectContext) {
        _controller = StateObject(wrappedValue: InvoiceController(viewContext: viewContext))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Invoice Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Invoice")
                        .font(.headline)
                        .padding(.horizontal)

                    Picker("Select Invoice", selection: $selectedInvoice) {
                        ForEach(controller.filteredInvoices) { invoice in
                            Text(invoice.workOrder?.customer?.name ?? "Unknown Customer")
                                .tag(invoice as Invoice?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    )
                }
                .padding(.horizontal)

                // Invoice Total Display
                if let invoice = selectedInvoice {
                    VStack {
                        Text("Invoice Total")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("$\(String(format: "%.2f", invoice.computedTotalAmount))")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                    )
                } else {
                    Text("Please select an invoice to view the total.")
                        .foregroundColor(.gray)
                        .italic()
                        .padding()
                }

                // Pay Button
                if let invoice = selectedInvoice {
                    PayButton(totalAmount: invoice.computedTotalAmount) {
                        startPayment(for: invoice)
                    }
                }

                // Processing Indicator
                if isPaymentProcessing {
                    ProgressView("Processing Payment...")
                        .padding()
                }

                // Error Display
                if let error = paymentError {
                    Text(error)
                        .foregroundColor(.red)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Payments")
        }
    }

    // MARK: - Start Payment
    private func startPayment(for invoice: Invoice) {
        guard invoice.computedTotalAmount > 0 else {
            paymentError = "Invalid invoice amount."
            return
        }

        isPaymentProcessing = true
        paymentError = nil

        let paymentHandler = PaymentHandler()
        paymentHandler.startPayment(
            for: invoice.computedTotalAmount,
            withMerchantIdentifier: "merchant.SmarthutATL.Manager",
            customerName: invoice.workOrder?.customer?.name ?? "Customer",
            onSuccess: {
                isPaymentProcessing = false
                paymentError = nil
                print("Payment succeeded!")
            },
            onFailure: { error in
                isPaymentProcessing = false
                paymentError = error
            }
        )
    }
}

// MARK: - Pay Button Component
struct PayButton: View {
    let totalAmount: Double
    let onPay: () -> Void

    var body: some View {
        Button(action: onPay) {
            HStack {
                Image(systemName: "applelogo")
                Text("Pay with Apple Pay")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
            .accessibility(label: Text("Pay \(String(format: "%.2f", totalAmount)) with Apple Pay"))
        }
        .padding(.horizontal)
    }
}
