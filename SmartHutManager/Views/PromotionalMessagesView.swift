import SwiftUI
import MessageUI

struct PromotionalMessagesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Customer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)]
    ) private var customers: FetchedResults<Customer>
    
    @State private var promotionTitle: String = ""
    @State private var promotionDescription: String = ""
    @State private var discount: String = ""
    @State private var selectedCustomer: Customer? = nil
    @State private var isShowingCustomerList = false
    @State private var isShowingMailView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showBadge = false
    @State private var progress: Double = 0.0

    var body: some View {
        VStack(spacing: 20) {
            // Progress Tracker
            progressBar

            // Promotion Title Input
            TextField("Promotion Title", text: $promotionTitle)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(promotionTitle.isEmpty ? Color.red : Color.green, lineWidth: 1)
                )
                .onChange(of: promotionTitle) { _ in updateProgress() }

            // Promotion Description Input
            TextEditor(text: $promotionDescription)
                .frame(height: 120)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    Group {
                        if promotionDescription.isEmpty {
                            Text("Enter the details of your promotion here...")
                                .foregroundColor(.gray)
                                .padding(10)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
                .onChange(of: promotionDescription) { _ in updateProgress() }

            // Discount Input
            TextField("Discount (e.g., 10%, $5 off)", text: $discount)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(discount.isEmpty ? Color.red : Color.green, lineWidth: 1)
                )
                .onChange(of: discount) { _ in updateProgress() }
            
            // Customer Picker
            Button(action: {
                isShowingCustomerList.toggle()
            }) {
                HStack {
                    Text(selectedCustomer?.name ?? "Select Customer")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
                .padding()
                .background(selectedCustomer == nil ? Color.gray : Color.blue)
                .cornerRadius(8)
            }
            .sheet(isPresented: $isShowingCustomerList) {
                CustomerPickerView(selectedCustomer: $selectedCustomer)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onChange(of: selectedCustomer) { _ in updateProgress() }
            
            // Action Buttons
            actionButtons

            // Badge Animation
            if showBadge {
                Text("🎉 First Promotion Created! 🎉")
                    .font(.headline)
                    .foregroundColor(.green)
                    .transition(.scale)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Create Promotion")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $isShowingMailView) {
            MailComposeView(
                recipients: [selectedCustomer?.email ?? ""].compactMap { $0 },
                subject: promotionTitle,
                messageBody: buildEmailBody(),
                attachmentData: Data(),
                attachmentMimeType: "",
                attachmentFileName: ""
            )
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack {
            Text("Progress: \(Int(progress * 100))%")
                .font(.footnote)
                .foregroundColor(.gray)
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                .padding(.horizontal)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack {
            Button(action: {
                prepareEmailPromotions()
                showBadge = true // Show badge on success
                withAnimation(.easeInOut) {
                    showBadge = false
                }
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text("Send Email")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!isFormValid)

            Button(action: {
                sendTextPromotion()
                showBadge = true // Show badge on success
                withAnimation(.easeInOut) {
                    showBadge = false
                }
            }) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Send Text")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(!isFormValid)
        }
        .padding(.top, 16)
    }

    // MARK: - Helper Methods
    private var isFormValid: Bool {
        !promotionTitle.isEmpty && !promotionDescription.isEmpty && !discount.isEmpty && selectedCustomer != nil
    }

    private func updateProgress() {
        let totalFields = 4.0
        var completedFields = 0.0

        if !promotionTitle.isEmpty { completedFields += 1 }
        if !promotionDescription.isEmpty { completedFields += 1 }
        if !discount.isEmpty { completedFields += 1 }
        if selectedCustomer != nil { completedFields += 1 }

        progress = completedFields / totalFields
    }

    private func prepareEmailPromotions() {
        if MFMailComposeViewController.canSendMail() {
            isShowingMailView = true
        } else {
            showAlert = true
            alertMessage = "Mail services are not available."
        }
    }

    private func sendTextPromotion() {
        guard let phoneNumber = selectedCustomer?.phoneNumber else {
            showAlert = true
            alertMessage = "Invalid phone number for \(selectedCustomer?.name ?? "Unknown")."
            return
        }
        
        let textBody = buildTextBody()
        
        if let url = URL(string: "sms:\(phoneNumber)&body=\(textBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        } else {
            showAlert = true
            alertMessage = "Unable to send text to \(phoneNumber)."
        }
    }
    
    private func buildEmailBody() -> String {
        """
        Hello \(selectedCustomer?.name ?? ""),
        
        We have an exciting promotion for you:
        
        \(promotionTitle)
        
        \(promotionDescription)
        
        Enjoy this offer: \(discount)
        
        Best regards,
        SmartHutManager
        """
    }
    
    private func buildTextBody() -> String {
        """
        \(promotionTitle): \(promotionDescription). Discount: \(discount)
        """
    }
}
