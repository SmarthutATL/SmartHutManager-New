import SwiftUI

struct AddLeadView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var pipelineStage = "New"
    @State private var notes = ""

    private let pipelineStages = ["New", "Contacted", "In Progress", "Closed"]

    var existingCustomer: Customer?
    var onSave: (Lead) -> Void

    init(existingCustomer: Customer?, onSave: @escaping (Lead) -> Void) {
        self.existingCustomer = existingCustomer
        self.onSave = onSave

        // Pre-fill fields if a customer is passed
        if let customer = existingCustomer {
            _name = State(initialValue: customer.name ?? "")
            _email = State(initialValue: customer.email ?? "")
            _phone = State(initialValue: customer.phoneNumber ?? "")
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Lead Information")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                    TextField("Phone", text: $phone)
                }

                Section(header: Text("Pipeline Stage")) {
                    Picker("Stage", selection: $pipelineStage) {
                        ForEach(pipelineStages, id: \.self) { stage in
                            Text(stage)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Lead")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newLead = Lead(
                            id: UUID().uuidString,
                            name: name,
                            email: email,
                            phone: phone,
                            pipelineStage: pipelineStage,
                            score: 0, // Initial score
                            lastActivity: Date(),
                            notes: notes,
                            createdAt: Date()
                        )
                        onSave(newLead)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
