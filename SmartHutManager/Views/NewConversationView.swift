import SwiftUI
import CoreData

struct NewConversationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedParticipant: String = "Technician" // Default to Technician
    @State private var selectedTechnician: Tradesmen? = nil
    @State private var selectedCustomer: Customer? = nil
    @State private var initialMessage: String = ""

    @State private var technicians: [Tradesmen] = []
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)]
    ) private var customers: FetchedResults<Customer>
    
    var onSave: (() -> Void)?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Participant Type")) {
                    Picker("Participant Type", selection: $selectedParticipant) {
                        Text("Technician").tag("Technician")
                        Text("Customer").tag("Customer")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                if selectedParticipant == "Technician" {
                    Section(header: Text("Select Technician")) {
                        Picker("Technician", selection: $selectedTechnician) {
                            ForEach(technicians, id: \.self) { technician in
                                Text(technician.name ?? "Unknown Technician")
                                    .tag(technician as Tradesmen?)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                } else if selectedParticipant == "Customer" {
                    Section(header: Text("Select Customer")) {
                        Picker("Customer", selection: $selectedCustomer) {
                            ForEach(customers, id: \.self) { customer in
                                Text(customer.name ?? "Unknown Customer")
                                    .tag(customer as Customer?)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                    }
                }

                Section(header: Text("Initial Message")) {
                    TextField("Type your message...", text: $initialMessage)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .navigationTitle("New Conversation")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        createConversationAndSendMessage()
                        onSave?()
                        dismiss()
                    }
                    .disabled((selectedTechnician == nil && selectedCustomer == nil) || initialMessage.isEmpty)
                }
            }
            .onAppear {
                technicians = fetchTechnicians()
            }
        }
    }

    private func createConversationAndSendMessage() {
        // Extract phone number
        let phoneNumber: String?
        if selectedParticipant == "Technician", let technician = selectedTechnician {
            phoneNumber = technician.phoneNumber
        } else if selectedParticipant == "Customer", let customer = selectedCustomer {
            phoneNumber = customer.phoneNumber
        } else {
            phoneNumber = nil
        }

        // Ensure phone number exists
        guard let phone = phoneNumber, !phone.isEmpty else {
            print("No phone number available.")
            return
        }

        // Send SMS
        let messageBody = initialMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:\(phone)&body=\(messageBody)") {
            UIApplication.shared.open(url)
        } else {
            print("Failed to create SMS URL.")
        }

        // Save conversation and message
        let newConversation = Conversation(context: viewContext)
        newConversation.id = UUID()
        newConversation.timestamp = Date()
        newConversation.lastMessage = initialMessage

        if selectedParticipant == "Technician", let technician = selectedTechnician {
            newConversation.name = technician.name
            newConversation.participants = "Technician: \(technician.name ?? "Unknown")"
        } else if selectedParticipant == "Customer", let customer = selectedCustomer {
            newConversation.name = customer.name
            newConversation.participants = "Customer: \(customer.name ?? "Unknown")"
        }

        let newMessage = Message(context: viewContext)
        newMessage.id = UUID()
        newMessage.content = initialMessage
        newMessage.timestamp = Date()
        newMessage.sender = "admin"
        newMessage.conversation = newConversation

        do {
            try viewContext.save()
        } catch {
            print("Failed to save conversation and message: \(error)")
        }
    }

    private func fetchTechnicians() -> [Tradesmen] {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching technicians: \(error)")
            return []
        }
    }
}
