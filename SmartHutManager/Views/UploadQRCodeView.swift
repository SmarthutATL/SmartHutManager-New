import SwiftUI
import CoreData

struct UploadQRCodeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss // Environment to handle dismissing the view
    @FetchRequest(
        entity: PaymentQRCode.entity(),
        sortDescriptors: []
    ) private var paymentQRCodes: FetchedResults<PaymentQRCode>
    
    @State private var showImagePickerForZelle = false
    @State private var showImagePickerForPayPal = false
    @State private var showOverwriteAlert = false
    @State private var overwriteType: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Custom Back Button with "Manage Payments" title
                HStack {
                    Button(action: {
                        dismiss() // Dismiss the view
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Manage Payments") // Back button title
                                .fontWeight(.regular) // Non-bold font style
                        }
                        .foregroundColor(.blue)
                        .font(.headline)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Header
                Text("Upload QR Codes")
                    .font(.largeTitle.bold())

                VStack(spacing: 16) {
                    // Zelle QR Code Upload
                    Button(action: { showOverwriteAlert(for: "Zelle") }) {
                        GenerateLinkButtonContent(
                            label: "Upload Zelle QR Code",
                            imageName: "zelle_logo", // Logo for Zelle
                            gradient: Gradient(colors: [Color.purple, Color.blue])
                        )
                    }
                    .sheet(isPresented: $showImagePickerForZelle) {
                        ImagePicker(selectedImage: Binding(
                            get: { nil },
                            set: { image in
                                saveQRCode(image: image, type: "Zelle")
                            }
                        ))
                    }

                    // PayPal QR Code Upload
                    Button(action: { showOverwriteAlert(for: "PayPal") }) {
                        GenerateLinkButtonContent(
                            label: "Upload PayPal QR Code",
                            imageName: "paypal_logo", // Logo for PayPal
                            gradient: Gradient(colors: [Color.blue, Color.cyan])
                        )
                    }
                    .sheet(isPresented: $showImagePickerForPayPal) {
                        ImagePicker(selectedImage: Binding(
                            get: { nil },
                            set: { image in
                                saveQRCode(image: image, type: "PayPal")
                            }
                        ))
                    }
                }
                .padding()
            }
            .padding()
            .alert(isPresented: $showOverwriteAlert) {
                Alert(
                    title: Text("Overwrite QR Code"),
                    message: Text("Uploading a new QR code will overwrite the existing \(overwriteType ?? "") QR code. Do you want to continue?"),
                    primaryButton: .destructive(Text("Continue")) {
                        if overwriteType == "Zelle" {
                            showImagePickerForZelle = true
                        } else if overwriteType == "PayPal" {
                            showImagePickerForPayPal = true
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true) // Hide the default back button
    }
    
    private func showOverwriteAlert(for type: String) {
        overwriteType = type
        let hasExistingQRCode = paymentQRCodes.first(where: { $0.type == type }) != nil
        if hasExistingQRCode {
            showOverwriteAlert = true
        } else {
            if type == "Zelle" {
                showImagePickerForZelle = true
            } else if type == "PayPal" {
                showImagePickerForPayPal = true
            }
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
