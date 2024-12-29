import SwiftUI
import CoreData

struct GenerateLinksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: PaymentQRCode.entity(),
        sortDescriptors: []
    ) private var paymentQRCodes: FetchedResults<PaymentQRCode>
    
    @StateObject private var controller: InvoiceController
    @State private var selectedInvoice: Invoice? = nil
    @State private var showZelleQRCode = false
    @State private var showPayPalQRCode = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(viewContext: NSManagedObjectContext) {
        _controller = StateObject(wrappedValue: InvoiceController(viewContext: viewContext))
    }
    
    private var zelleQRCode: UIImage? {
        if let data = paymentQRCodes.first(where: { $0.type == "Zelle" })?.qrCode,
           let image = UIImage(data: data) {
            print("Zelle QR Code found: \(image)")
            return image
        } else {
            print("No Zelle QR Code found.")
            return nil
        }
    }
    
    private var paypalQRCode: UIImage? {
        if let data = paymentQRCodes.first(where: { $0.type == "PayPal" })?.qrCode,
           let image = UIImage(data: data) {
            print("PayPal QR Code found: \(image)")
            return image
        } else {
            print("No PayPal QR Code found.")
            return nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Generate Payment Links")
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                // Invoice Selector
                VStack(spacing: 16) {
                    Text("Select an Invoice")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("Select Invoice", selection: $selectedInvoice) {
                        ForEach(controller.filteredInvoices) { invoice in
                            Text(invoice.workOrder?.customer?.name ?? "Unknown Customer")
                                .tag(invoice as Invoice?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
                }
                .padding(.horizontal)

                // Invoice Summary
                if let invoice = selectedInvoice {
                    InvoiceSummaryCard(invoice: invoice)
                } else {
                    EmptyStateCard()
                }

                Spacer()

                // Generate Links Section
                VStack(spacing: 16) {
                    // Generate Zelle Link
                    Button(action: {
                        if zelleQRCode == nil {
                            alertMessage = "Please upload a Zelle QR code before generating a link."
                            showAlert = true
                        } else if selectedInvoice == nil {
                            alertMessage = "Please select an invoice before generating a link."
                            showAlert = true
                        } else {
                            showZelleQRCode = true
                        }
                    }) {
                        GenerateLinkButtonContent(label: "Generate Zelle Link", imageName: "zelle_logo", gradient: Gradient(colors: [Color.purple, Color.blue]))
                    }
                    .sheet(isPresented: $showZelleQRCode) {
                        if let qrImage = zelleQRCode {
                            QRCodeFullScreenView(image: qrImage)
                        }
                    }

                    // Generate PayPal Link
                    Button(action: {
                        if paypalQRCode == nil {
                            alertMessage = "Please upload a PayPal QR code before generating a link."
                            showAlert = true
                        } else if selectedInvoice == nil {
                            alertMessage = "Please select an invoice before generating a link."
                            showAlert = true
                        } else {
                            showPayPalQRCode = true
                        }
                    }) {
                        GenerateLinkButtonContent(label: "Generate PayPal Link", imageName: "paypal_logo", gradient: Gradient(colors: [Color.blue, Color.cyan]))
                    }
                    .sheet(isPresented: $showPayPalQRCode) {
                        if let qrImage = paypalQRCode {
                            QRCodeFullScreenView(image: qrImage)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Action Required"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}

// MARK: - GenerateLinkButtonContent
struct GenerateLinkButtonContent: View {
    let label: String
    let imageName: String
    let gradient: Gradient
    
    var body: some View {
        HStack {
            Image(imageName)
                .resizable()
                .frame(width: 24, height: 24)
            Text(label)
                .fontWeight(.semibold)
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing))
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

// MARK: - QRCodeFullScreenView
struct QRCodeFullScreenView: View {
    let image: UIImage
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
        }
    }
}

// MARK: - InvoiceSummaryCard
struct InvoiceSummaryCard: View {
    let invoice: Invoice

    var body: some View {
        VStack(spacing: 8) {
            Text(invoice.workOrder?.customer?.name ?? "Unknown Customer")
                .font(.headline)

            Text("$\(String(format: "%.2f", invoice.computedTotalAmount))")
                .font(.title.bold())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemGray6))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

// MARK: - EmptyStateCard
struct EmptyStateCard: View {
    var body: some View {
        VStack {
            Text("No Invoice Selected")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}
