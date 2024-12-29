import SwiftUI
import CoreData
import PhotosUI

struct ManagePaymentsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var controller: InvoiceController
    @FetchRequest(
        entity: PaymentQRCode.entity(),
        sortDescriptors: []
    ) private var paymentQRCodes: FetchedResults<PaymentQRCode>
    
    @State private var selectedInvoice: Invoice? = nil
    @State private var showZelleQRCode = false
    @State private var showPayPalQRCode = false
    @State private var showImagePickerForZelle = false
    @State private var showImagePickerForPayPal = false

    init(viewContext: NSManagedObjectContext) {
        _controller = StateObject(wrappedValue: InvoiceController(viewContext: viewContext))
    }
    
    private var zelleQRCode: UIImage? {
        paymentQRCodes.first(where: { $0.type == "Zelle" })?.qrCodeImage
    }
    
    private var paypalQRCode: UIImage? {
        paymentQRCodes.first(where: { $0.type == "PayPal" })?.qrCodeImage
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Receive Payments")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

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

                    // QR Code Uploads and Buttons
                    VStack(spacing: 16) {
                        // Zelle Section
                        VStack(spacing: 8) {
                            Button(action: { showImagePickerForZelle.toggle() }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Upload Zelle QR Code")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(16)
                                .shadow(radius: 5)
                            }
                            .sheet(isPresented: $showImagePickerForZelle) {
                                ImagePicker(selectedImage: Binding(
                                    get: { zelleQRCode },
                                    set: { image in
                                        saveQRCode(image: image, type: "Zelle")
                                    }
                                ))
                            }

                            GenerateLinkButton(label: "Generate Zelle Link", imageName: "zelle_logo", isDisabled: zelleQRCode == nil, gradient: Gradient(colors: [Color.purple, Color.blue])) {
                                showZelleQRCode = true
                            }
                            .sheet(isPresented: $showZelleQRCode) {
                                if let qrImage = zelleQRCode {
                                    QRCodeFullScreenView(image: qrImage)
                                }
                            }
                        }

                        // PayPal Section
                        VStack(spacing: 8) {
                            Button(action: { showImagePickerForPayPal.toggle() }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Upload PayPal QR Code")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(16)
                                .shadow(radius: 5)
                            }
                            .sheet(isPresented: $showImagePickerForPayPal) {
                                ImagePicker(selectedImage: Binding(
                                    get: { paypalQRCode },
                                    set: { image in
                                        saveQRCode(image: image, type: "PayPal")
                                    }
                                ))
                            }

                            GenerateLinkButton(label: "Generate PayPal Link", imageName: "paypal_logo", isDisabled: paypalQRCode == nil, gradient: Gradient(colors: [Color.blue, Color.cyan])) {
                                showPayPalQRCode = true
                            }
                            .sheet(isPresented: $showPayPalQRCode) {
                                if let qrImage = paypalQRCode {
                                    QRCodeFullScreenView(image: qrImage)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
        }
    }
    
    // Save QR Code to CoreData
    private func saveQRCode(image: UIImage?, type: String) {
        guard let image = image, let imageData = image.pngData() else { return }
        
        if let existingQRCode = paymentQRCodes.first(where: { $0.type == type }) {
            existingQRCode.qrCode = imageData
        } else {
            let newQRCode = PaymentQRCode(context: viewContext)
            newQRCode.type = type
            newQRCode.qrCode = imageData
        }
        
        try? viewContext.save()
    }
}

// MARK: - Components

struct GenerateLinkButton: View {
    let label: String
    let imageName: String
    let isDisabled: Bool
    let gradient: Gradient
    let onGenerate: () -> Void

    var body: some View {
        Button(action: onGenerate) {
            HStack {
                Image(imageName)
                    .resizable()
                    .frame(width: 20, height: 20)
                Text(label)
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: gradient, startPoint: .leading, endPoint: .trailing))
            .cornerRadius(16)
            .shadow(radius: 5)
        }
        .disabled(isDisabled)
    }
}

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
