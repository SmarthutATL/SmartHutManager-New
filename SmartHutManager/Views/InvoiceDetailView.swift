import SwiftUI
import MessageUI // For sending email with invoice PDF
import PDFKit    // For generating PDF

struct InvoiceDetailView: View {
    @ObservedObject var invoice: Invoice // Observe changes in the invoice

    @State private var showingMailCompose = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var pdfData: Data? = nil
    @State private var isSaving = false // Add state to track saving status

    // Computed property to calculate total amount from services and materials with 4% tax
    var totalAmount: Double {
        // Calculate the total for itemized services
        let serviceTotal = invoice.itemizedServicesArray.reduce(0) { total, service in
            total + (service.unitPrice * Double(service.quantity))
        }
        
        // Calculate the total for materials
        let materialTotal = invoice.workOrder?.materialsArray.reduce(0) { total, material in
            total + (material.price * Double(material.quantity))
        } ?? 0.0
        
        // Calculate subtotal before tax
        let subtotal = serviceTotal + materialTotal
        
        // Apply 4% tax
        let taxAmount = subtotal * 0.04
        
        // Return total amount including tax
        return subtotal + taxAmount
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Logo and Invoice Info
                HStack(alignment: .top) {
                    if let logo = UIImage(named: "smarthut_logo") {
                        Image(uiImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(20)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invoice Info")
                            .font(.headline)
                        HStack {
                            Text("Invoice #:")
                            Spacer()
                            Text("\(invoice.invoiceNumber)")
                        }
                        HStack {
                            Text("Total:")
                            Spacer()
                            Text("$\(totalAmount, specifier: "%.2f")") // Updated to use computed total
                        }
                        HStack {
                            Text("Status:")
                            Spacer()
                            Text(invoice.status ?? "Unpaid")
                        }
                    }
                    .frame(width: 150)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                // Customer Info
                customerInfoSection()

                // Work Order Info
                workOrderInfoSection()

                // Itemized Services
                itemizedServicesSection()

                // Materials Section (Added below Itemized Services)
                materialsSection()

                // Toggle Payment Status Button
                togglePaymentStatusButton()

                // Send Invoice as PDF Button
                sendInvoiceAsPDFButton()
            }
            .padding()
        }
        .navigationTitle("Invoice #\(invoice.invoiceNumber)")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showingMailCompose) {
            if let pdfData = pdfData {
                MailComposeView(recipients: [invoice.workOrder?.customer?.email ?? ""],
                                subject: "Invoice #\(invoice.invoiceNumber)",
                                messageBody: generateEmailBody(),
                                attachmentData: pdfData,
                                attachmentMimeType: "application/pdf",
                                attachmentFileName: "Invoice_\(invoice.invoiceNumber).pdf")
            }
        }
    }

    // MARK: - Helper Views
    private func customerInfoSection() -> some View {
        Group {
            Text("Customer Info")
                .font(.headline)
            
            if let customer = invoice.workOrder?.customer {
                HStack {
                    Text("Name:")
                    Spacer()
                    Text(customer.name ?? "No Name")
                }
                HStack {
                    Text("Address:")
                    Spacer()
                    Text(customer.address ?? "No Address")
                }
                HStack {
                    Text("Phone:")
                    Spacer()
                    Text(customer.phoneNumber ?? "No Phone Number")
                }
            } else {
                Text("No customer information available")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func workOrderInfoSection() -> some View {
        Group {
            Text("Work Order Info")
                .font(.headline)
            if let workOrder = invoice.workOrder {
                HStack {
                    Text("Category:")
                    Spacer()
                    Text(workOrder.category ?? "N/A")
                }
                HStack {
                    Text("Description:")
                    Spacer()
                    Text(workOrder.workOrderDescription ?? "No description")
                }
            } else {
                Text("No associated work order")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func itemizedServicesSection() -> some View {
        Group {
            Text("Itemized Services")
                .font(.headline)

            if invoice.itemizedServicesArray.isEmpty {
                Text("No itemized services")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(invoice.itemizedServicesArray.indices, id: \.self) { index in
                        let service = invoice.itemizedServicesArray[index]
                        HStack {
                            Text(service.description)
                            Spacer()
                            Text("\(service.quantity) x $\(service.unitPrice, specifier: "%.2f")")
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // MARK: - Materials Section (Updated to use `name` and `price`)
    private func materialsSection() -> some View {
        Group {
            Text("Materials")
                .font(.headline)

            if let workOrder = invoice.workOrder {
                let materialsArray = workOrder.materialsArray

                if materialsArray.isEmpty {
                    Text("No materials")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(materialsArray) { material in
                            HStack {
                                Text(material.name) // Changed from `description` to `name`
                                Spacer()
                                Text("\(material.quantity) x $\(material.price, specifier: "%.2f")")  // Changed to use `price`
                            }
                        }
                    }
                }
            } else {
                Text("No associated work order")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private func togglePaymentStatusButton() -> some View {
        Button(action: {
            togglePaymentStatus()
        }) {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                HStack {
                    Text(invoice.status == "Paid" ? "Mark as Unpaid" : "Mark as Paid")
                    Spacer()
                    Image(systemName: invoice.status == "Paid" ? "xmark.circle" : "checkmark.circle")
                }
            }
        }
        .padding()
        .background(invoice.status == "Paid" ? Color.red : Color.green)
        .foregroundColor(.white)
        .cornerRadius(10)
    }

    private func sendInvoiceAsPDFButton() -> some View {
        Button(action: {
            isSaving = true // Show a progress indicator if needed
            createPDF { data in
                if let data = data {
                    DispatchQueue.main.async {
                        pdfData = data
                        isSaving = false
                        showingMailCompose = true // Trigger the mail view only when PDF is ready
                    }
                } else {
                    DispatchQueue.main.async {
                        isSaving = false
                        alertMessage = "Failed to generate PDF."
                        showAlert = true
                    }
                }
            }
        }) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                } else {
                    Text("Send Invoice as PDF")
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
    }

    // MARK: - Helper Methods
    private func togglePaymentStatus() {
        withAnimation {
            invoice.status = invoice.status == "Paid" ? "Unpaid" : "Paid"
            isSaving = true
        }

        DispatchQueue.global(qos: .userInitiated).async {
            invoice.managedObjectContext?.perform {
                do {
                    try invoice.managedObjectContext?.save()
                    DispatchQueue.main.async {
                        isSaving = false
                    }
                } catch {
                    DispatchQueue.main.async {
                        invoice.status = invoice.status == "Paid" ? "Unpaid" : "Paid"
                        alertMessage = "Failed to update payment status. Please try again."
                        showAlert = true
                        isSaving = false
                    }
                }
            }
        }
    }

    // Helper function to format dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // Function to generate the email body
    private func generateEmailBody() -> String {
        guard let paymentMethod = invoice.paymentMethod else { return "" }

        let baseMessage = "Hi \(invoice.workOrder?.customer?.name ?? "Customer"),\n\nPlease find your invoice attached.\n\n"

        switch paymentMethod {
        case "Apple Pay":
            return baseMessage + "You can pay using Apple Pay at the time of service."
        case "PayPal":
            return baseMessage + "Please use this PayPal link to pay: https://www.paypal.me/smarthutatl/\(String(format: "%.2f", invoice.totalAmount))"
        case "Zelle":
            return baseMessage + "Please use Zelle to send payment to smarthutatl@gmail.com."
        case "Cash":
            return baseMessage + "Cash payment is expected at the time of job completion."
        default:
            return baseMessage
        }
    }

    // Function to create a PDF from the invoice details
    private func createPDF(completion: @escaping (Data?) -> Void) {
        let pdfMetaData = [
            kCGPDFContextCreator: "SmartHut",
            kCGPDFContextAuthor: "SmartHut",
            kCGPDFContextTitle: "Invoice #\(invoice.invoiceNumber)"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)

        let data = renderer.pdfData { (context) in
            context.beginPage()

            // Draw logo at the top
            if let logo = UIImage(named: "smarthut_logo") {
                let logoRect = CGRect(x: 20, y: 20, width: 100, height: 100)
                logo.draw(in: logoRect)
            }

            // Title: Invoice Number
            let title = "Invoice #\(invoice.invoiceNumber)"
            let titleAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)]
            title.draw(at: CGPoint(x: 140, y: 20), withAttributes: titleAttributes)

            // Starting Y position for the rest of the invoice
            var yPosition: CGFloat = 140

            // Customer Information Section
            if let customer = invoice.workOrder?.customer {
                let customerText = """
                Customer Information:
                Name: \(customer.name ?? "No Name")
                Address: \(customer.address ?? "No Address")
                Phone: \(customer.phoneNumber ?? "No Phone Number")
                """
                customerText.draw(at: CGPoint(x: 20, y: yPosition))
                yPosition += 60
            }

            // Invoice Details Section
            let serviceTotal = invoice.itemizedServicesArray.reduce(0) { total, service in
                total + (service.unitPrice * Double(service.quantity))
            }
            let materialTotal = invoice.workOrder?.materialsArray.reduce(0) { total, material in
                total + (material.price * Double(material.quantity))
            } ?? 0.0
            let subtotal = serviceTotal + materialTotal
            let taxAmount = subtotal * 0.04
            let formattedTotalAmount = String(format: "%.2f", subtotal + taxAmount)

            let invoiceDetails = """
            Invoice Information:
            Invoice #: \(invoice.invoiceNumber)
            Subtotal: $\(String(format: "%.2f", subtotal))
            Tax (4%): $\(String(format: "%.2f", taxAmount))
            Total: $\(formattedTotalAmount)
            Status: \(invoice.status ?? "Unpaid")
            Due Date: \(invoice.dueDate != nil ? formatDate(invoice.dueDate!) : "No due date")
            """
            invoiceDetails.draw(at: CGPoint(x: 20, y: yPosition))
            yPosition += 100

            // Work Order Information Section
            if let workOrder = invoice.workOrder {
                let workOrderText = """
                Work Order Information:
                Category: \(workOrder.category ?? "N/A")
                Description: \(workOrder.workOrderDescription ?? "No description")
                """
                workOrderText.draw(at: CGPoint(x: 20, y: yPosition))
                yPosition += 60
            }

            // Itemized Services Section
            if !invoice.itemizedServicesArray.isEmpty {
                var serviceSection = "Itemized Services:\n"
                for service in invoice.itemizedServicesArray {
                    let priceString = String(format: "%.2f", service.unitPrice)
                    let line = "\(service.description) - \(service.quantity) x $\(priceString)\n"
                    serviceSection.append(line)
                }
                serviceSection.draw(at: CGPoint(x: 20, y: yPosition))
                yPosition += CGFloat(invoice.itemizedServicesArray.count * 20) + 20
            }

            // Materials Section
            if let workOrder = invoice.workOrder, !workOrder.materialsArray.isEmpty {
                var materialsSection = "Materials:\n"
                for material in workOrder.materialsArray {
                    let priceString = String(format: "%.2f", material.price)
                    let line = "\(material.name) - \(material.quantity) x $\(priceString)\n"
                    materialsSection.append(line)
                }
                materialsSection.draw(at: CGPoint(x: 20, y: yPosition))
                yPosition += CGFloat(workOrder.materialsArray.count * 20) + 20
            }

            // Footer: Thank You Note
            let footerText = "Thank you for your business!"
            footerText.draw(at: CGPoint(x: 20, y: pageHeight - 40), withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)])
        }

        completion(data)
    }
}
